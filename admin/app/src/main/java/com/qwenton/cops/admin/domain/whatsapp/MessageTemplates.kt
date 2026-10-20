package com.qwenton.cops.admin.domain.whatsapp

import com.qwenton.cops.admin.domain.model.Order

enum class TemplateType {
    ORDER_CONFIRMATION,
    PAYMENT_REMINDER,
    SHIPPING_DISPATCHED,
    DELIVERY_FOLLOWUP
}

data class MessageTemplate(
    val id: String,
    val type: TemplateType,
    val title: String,
    val language: String, // "en" or "hi"
    val templateBody: String
) {
    fun render(order: Order, storeName: String = "Our Store"): String {
        return templateBody
            .replace("{customer_name}", order.customerName.ifBlank { "Customer" })
            .replace("{order_number}", order.orderNumber)
            .replace("{order_total}", order.formatRupees(order.netSalesPaise))
            .replace("{courier_name}", order.courierName ?: "our courier partner")
            .replace("{tracking_number}", order.trackingNumber ?: "Pending")
            .replace("{store_name}", storeName)
    }

    companion object {
        val defaultTemplates = listOf(
            MessageTemplate(
                id = "en_confirm",
                type = TemplateType.ORDER_CONFIRMATION,
                title = "Order Confirmed (EN)",
                language = "en",
                templateBody = "Namaste {customer_name}! 🙏\n\n" +
                        "Thank you for ordering with *{store_name}*!\n\n" +
                        "📦 *Order ID:* #{order_number}\n" +
                        "💰 *Total Amount:* {order_total}\n" +
                        "💳 *Payment:* FamGateway Verified\n\n" +
                        "We are preparing your parcel for dispatch. You will receive tracking details shortly."
            ),
            MessageTemplate(
                id = "hi_confirm",
                type = TemplateType.ORDER_CONFIRMATION,
                title = "Order Confirmed (हिंदी)",
                language = "hi",
                templateBody = "नमस्ते {customer_name}! 🙏\n\n" +
                        "*{store_name}* पर ऑर्डर करने के लिए धन्यवाद!\n\n" +
                        "📦 *ऑर्डर नंबर:* #{order_number}\n" +
                        "💰 *कुल राशि:* {order_total}\n" +
                        "💳 *भुगतान स्थिति:* FamGateway सत्यापित\n\n" +
                        "आपका पार्सल तैयार किया जा रहा है। डिस्पैच होते ही आपको ट्रैकिंग नंबर भेज दिया जाएगा।"
            ),
            MessageTemplate(
                id = "en_shipping",
                type = TemplateType.SHIPPING_DISPATCHED,
                title = "Shipping Dispatched (EN)",
                language = "en",
                templateBody = "Hello {customer_name}! 🚚\n\n" +
                        "Good news! Your order #{order_number} from *{store_name}* has been shipped.\n\n" +
                        "📦 *Courier:* {courier_name}\n" +
                        "🔍 *Tracking No:* {tracking_number}\n\n" +
                        "Expect delivery within 3–5 working days."
            ),
            MessageTemplate(
                id = "hi_shipping",
                type = TemplateType.SHIPPING_DISPATCHED,
                title = "Shipping Dispatched (हिंदी)",
                language = "hi",
                templateBody = "नमस्ते {customer_name}! 🚚\n\n" +
                        "खुशखबरी! *{store_name}* से आपका ऑर्डर #{order_number} भेज दिया गया है।\n\n" +
                        "📦 *कूरियर पार्टनर:* {courier_name}\n" +
                        "🔍 *ट्रैकिंग नंबर:* {tracking_number}\n\n" +
                        "पार्सल अगले 3-5 कार्य दिवसों में पहुँच जाएगा।"
            )
        )
    }
}
