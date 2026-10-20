import '../../../core/models/order.dart';

enum TemplateType {
  orderConfirmation,
  paymentReminder,
  codConfirmation,
  shippingTracking,
  deliveredFeedback,
  custom,
}

class MessageTemplate {
  final String id;
  final TemplateType type;
  final String title;
  final String language; // 'en' or 'hi'
  final String bodyTemplate;

  const MessageTemplate({
    required this.id,
    required this.type,
    required this.title,
    required this.language,
    required this.bodyTemplate,
  });

  /// Interpolates template variables with real order and customer data
  String render(Order order, {String? storeName}) {
    final customer = order.customer;
    final customerName = customer?.name ?? 'Customer';
    final itemsList = order.items.isNotEmpty
        ? order.items.map((i) => '• ${i.quantity}x Item').join('\n')
        : 'Your item';

    var rendered = bodyTemplate
        .replaceAll('{customer_name}', customerName)
        .replaceAll('{order_number}', order.orderNumber)
        .replaceAll('{order_total}', order.netSales.toFormattedRupees())
        .replaceAll('{items}', itemsList)
        .replaceAll('{store_name}', storeName ?? 'Our Store')
        .replaceAll('{courier_name}', order.courierName ?? 'our courier partner')
        .replaceAll('{tracking_number}', order.trackingNumber ?? 'Pending');

    return rendered;
  }

  static List<MessageTemplate> get defaultTemplates {
    return [
      // English Templates
      const MessageTemplate(
        id: 'en_order_confirm',
        type: TemplateType.orderConfirmation,
        title: 'Order Confirmation (EN)',
        language: 'en',
        bodyTemplate:
            'Namaste {customer_name}! 🙏\n\n'
            'Thank you for ordering with {store_name}!\n\n'
            '📦 *Order ID:* #{order_number}\n'
            '💰 *Total Amount:* {order_total}\n\n'
            'We are currently preparing your parcel. You will receive tracking details once dispatched.',
      ),
      const MessageTemplate(
        id: 'en_payment_reminder',
        type: TemplateType.paymentReminder,
        title: 'UPI Payment Reminder (EN)',
        language: 'en',
        bodyTemplate:
            'Hello {customer_name},\n\n'
            'Your order #{order_number} is reserved with {store_name}. Total payable: *{order_total}*.\n\n'
            'Kindly complete payment via UPI and share the screenshot/UTR reference here so we can pack your order today! 😊',
      ),
      const MessageTemplate(
        id: 'en_cod_confirm',
        type: TemplateType.codConfirmation,
        title: 'COD Doorstep Confirmation (EN)',
        language: 'en',
        bodyTemplate:
            'Namaste {customer_name},\n\n'
            'We received your Cash on Delivery (COD) order #{order_number} for {order_total}.\n\n'
            'To confirm your delivery address and prevent dispatch cancellation, please reply *YES* to this message. 🙏',
      ),
      const MessageTemplate(
        id: 'en_shipping_tracking',
        type: TemplateType.shippingTracking,
        title: 'Shipping & Tracking (EN)',
        language: 'en',
        bodyTemplate:
            'Great news {customer_name}! 🚀\n\n'
            'Your order #{order_number} has been shipped via *{courier_name}*.\n'
            '📍 *Tracking No:* {tracking_number}\n\n'
            'Expected delivery within 3–5 business days.',
      ),
      const MessageTemplate(
        id: 'en_delivered_feedback',
        type: TemplateType.deliveredFeedback,
        title: 'Delivered & Review (EN)',
        language: 'en',
        bodyTemplate:
            'Namaste {customer_name}! Hope you loved your order from {store_name}! ✨\n\n'
            'If you liked it, please share a photo or review with us. We truly appreciate your support for our small business! ❤️',
      ),

      // Hindi Templates (हिंदी)
      const MessageTemplate(
        id: 'hi_order_confirm',
        type: TemplateType.orderConfirmation,
        title: 'ऑर्डर कन्फर्मेशन (HI)',
        language: 'hi',
        bodyTemplate:
            'नमस्ते {customer_name} जी! 🙏\n\n'
            '{store_name} से ऑर्डर करने के लिए आपका बहुत-बहुत धन्यवाद!\n\n'
            '📦 *ऑर्डर नंबर:* #{order_number}\n'
            '💰 *कुल राशि:* {order_total}\n\n'
            'हम आपका पार्सल तैयार कर रहे हैं। डिस्पैच होते ही आपको ट्रैकिंग नंबर भेज दिया जाएगा।',
      ),
      const MessageTemplate(
        id: 'hi_payment_reminder',
        type: TemplateType.paymentReminder,
        title: 'पेमेंट रिमाइंडर (HI)',
        language: 'hi',
        bodyTemplate:
            'नमस्ते {customer_name} जी,\n\n'
            'आपका ऑर्डर #{order_number} सुरक्षित है। कुल राशि: *{order_total}*।\n\n'
            'कृपया UPI द्वारा पेमेंट पूरा करके स्क्रीनशॉट या UTR नंबर यहां साझा करें ताकि आज ही आपका पार्सल भेजा जा सके! 😊',
      ),
      const MessageTemplate(
        id: 'hi_cod_confirm',
        type: TemplateType.codConfirmation,
        title: 'COD डिलीवरी कन्फर्मेशन (HI)',
        language: 'hi',
        bodyTemplate:
            'नमस्ते {customer_name} जी,\n\n'
            'हमें {order_total} का आपका Cash on Delivery (COD) ऑर्डर #{order_number} प्राप्त हुआ है।\n\n'
            'डिलीवरी पक्की करने के लिए कृपया इस मैसेज का जवाब *YES* लिखकर दें। धन्यवाद! 🙏',
      ),
      const MessageTemplate(
        id: 'hi_shipping_tracking',
        type: TemplateType.shippingTracking,
        title: 'कूरियर ट्रैकिंग जानकारी (HI)',
        language: 'hi',
        bodyTemplate:
            'नमस्ते {customer_name} जी! 🚀\n\n'
            'आपका ऑर्डर #{order_number} *{courier_name}* द्वारा भेज दिया गया है।\n'
            '📍 *ट्रैकिंग नंबर:* {tracking_number}\n\n'
            'पार्सल 3 से 5 दिनों में आपके पते पर पहुंच जाएगा।',
      ),
    ];
  }
}
