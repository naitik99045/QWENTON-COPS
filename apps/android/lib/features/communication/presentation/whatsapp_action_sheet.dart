import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/order.dart';
import '../domain/message_template.dart';

class WhatsAppActionSheet extends StatefulWidget {
  final Order order;
  final String storeName;

  const WhatsAppActionSheet({
    super.key,
    required this.order,
    required this.storeName,
  });

  static Future<void> show(BuildContext context, Order order, String storeName) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => WhatsAppActionSheet(order: order, storeName: storeName),
    );
  }

  @override
  State<WhatsAppActionSheet> createState() => _WhatsAppActionSheetState();
}

class _WhatsAppActionSheetState extends State<WhatsAppActionSheet> {
  late List<MessageTemplate> _allTemplates;
  late MessageTemplate _selectedTemplate;
  late TextEditingController _messageController;
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _allTemplates = MessageTemplate.defaultTemplates;

    // Default to template matching order status
    _selectedTemplate = _getBestTemplate(widget.order.fulfilmentStatus);
    _selectedLanguage = _selectedTemplate.language;

    final renderedText = _selectedTemplate.render(widget.order, storeName: widget.storeName);
    _messageController = TextEditingController(text: renderedText);
  }

  MessageTemplate _getBestTemplate(FulfilmentStatus status) {
    if (status == FulfilmentStatus.paymentPending) {
      return _allTemplates.firstWhere((t) => t.type == TemplateType.paymentReminder && t.language == _selectedLanguage);
    } else if (status == FulfilmentStatus.codConfirmed) {
      return _allTemplates.firstWhere((t) => t.type == TemplateType.codConfirmation && t.language == _selectedLanguage);
    } else if (status == FulfilmentStatus.shipped) {
      return _allTemplates.firstWhere((t) => t.type == TemplateType.shippingTracking && t.language == _selectedLanguage);
    } else if (status == FulfilmentStatus.delivered) {
      return _allTemplates.firstWhere((t) => t.type == TemplateType.deliveredFeedback && t.language == _selectedLanguage);
    }
    return _allTemplates.firstWhere((t) => t.type == TemplateType.orderConfirmation && t.language == _selectedLanguage);
  }

  void _onTemplateSelected(MessageTemplate template) {
    setState(() {
      _selectedTemplate = template;
      _messageController.text = template.render(widget.order, storeName: widget.storeName);
    });
  }

  void _onLanguageChanged(String lang) {
    setState(() {
      _selectedLanguage = lang;
      final match = _allTemplates.firstWhere(
        (t) => t.type == _selectedTemplate.type && t.language == lang,
        orElse: () => _allTemplates.firstWhere((t) => t.language == lang),
      );
      _selectedTemplate = match;
      _messageController.text = match.render(widget.order, storeName: widget.storeName);
    });
  }

  void _sendViaWhatsApp() async {
    final phone = widget.order.customer?.phone ?? '';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final text = _messageController.text.trim();

    final uri = Uri.parse('whatsapp://send?phone=$digits&text=${Uri.encodeComponent(text)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(
          Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(text)}'),
          mode: LaunchMode.externalApplication,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp app')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.order.customer;
    final availableTemplates = _allTemplates.where((t) => t.language == _selectedLanguage).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 18,
          right: 18,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.chat_bubble, color: Color(0xFF25D366), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('WhatsApp Message Center', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('To: ${customer?.name ?? "Customer"} (+91 ${customer?.phone.replaceAll(RegExp(r'\D'), "")})',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),

              // Language Toggle (English vs हिंदी)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Template Language:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('English'),
                        selected: _selectedLanguage == 'en',
                        onSelected: (_) => _onLanguageChanged('en'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('हिंदी (Hindi)'),
                        selected: _selectedLanguage == 'hi',
                        onSelected: (_) => _onLanguageChanged('hi'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Template Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: availableTemplates.map((t) {
                    final isSelected = t.id == _selectedTemplate.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(t.title),
                        selected: isSelected,
                        selectedColor: Colors.blue.shade100,
                        onSelected: (_) => _onTemplateSelected(t),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Message Preview and Edit Box
              const Text('Message Preview (Editable):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _messageController,
                maxLines: 7,
                style: const TextStyle(fontSize: 13, height: 1.4),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _messageController.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message copied to clipboard!')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _sendViaWhatsApp,
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Send on WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
