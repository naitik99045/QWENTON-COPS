import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/product.dart';

class ShareLinkDialog extends StatelessWidget {
  final Product product;
  final String storefrontUrl;

  const ShareLinkDialog({
    super.key,
    required this.product,
    required this.storefrontUrl,
  });

  static Future<void> show(BuildContext context, Product product, String url) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ShareLinkDialog(product: product, storefrontUrl: url),
    );
  }

  void _shareViaWhatsApp(BuildContext context) async {
    final message = Uri.encodeComponent(
      '🛍️ Order "${product.name}" directly here:\n$storefrontUrl\n\n'
      '• Price: ${product.sellingPrice.toFormattedRupees()}\n'
      '• Pay securely with UPI or Cash on Delivery!',
    );
    final waUri = Uri.parse('whatsapp://send?text=$message');

    try {
      if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to web link
        final webUri = Uri.parse('https://wa.me/?text=$message');
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp app')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Share Product Link',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Customers can open this link on Instagram, YouTube Shorts, or WhatsApp and checkout without downloading an app.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            // Link Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      storefrontUrl,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'Copy Link',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: storefrontUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Share Options
            ElevatedButton.icon(
              onPressed: () => _shareViaWhatsApp(context),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Share on WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: storefrontUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied! Paste into your Instagram Bio or Story sticker.')),
                );
                Navigator.pop(context);
              },
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Copy for Instagram Bio / Story Sticker'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
