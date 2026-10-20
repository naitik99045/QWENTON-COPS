package com.qwenton.cops.admin.domain.model

data class OrderItem(
    val productId: String = "",
    val variantId: String? = null,
    val variantName: String? = null,
    val quantity: Int = 1,
    val unitPricePaise: Long = 0L,
    val unitCostPaise: Long = 0L
)

data class Order(
    val id: String = "",
    val orderNumber: String = "",
    val businessId: String = "",
    val customerId: String = "",
    val customerName: String = "",
    val customerPhone: String = "",
    val deliveryAddress: String = "",
    val city: String = "",
    val state: String = "",
    val pincode: String = "",
    val items: List<OrderItem> = emptyList(),
    val paymentMethod: String = "famgateway", // "famgateway", "cod", "upi"
    val paymentStatus: String = "pending",   // "pending", "paid", "cod_confirmed", "failed"
    val fulfilmentStatus: String = "new",    // "new", "payment_pending", "to_pack", "packed", "shipped", "delivered", "rto", "cancelled"
    val subtotalPaise: Long = 0L,
    val discountPaise: Long = 0L,
    val netSalesPaise: Long = 0L,
    val productCostPaise: Long = 0L,
    val packagingCostPaise: Long = 0L,
    val shippingPaise: Long = 0L,
    val paymentFeePaise: Long = 0L,
    val estimatedProfitPaise: Long = 0L,
    val realisedProfitPaise: Long? = null,
    val famgatewayTxnId: String? = null,
    val famgatewayOrderId: String? = null,
    val famgatewayUtr: String? = null,
    val courierName: String? = null,
    val trackingNumber: String? = null,
    val createdAt: String = "",
    val updatedAt: String = ""
) {
    fun toRupees(paise: Long): Double = paise / 100.0

    fun formatRupees(paise: Long): String {
        val rs = paise / 100.0
        return String.format("₹%,.2f", rs)
    }
}
