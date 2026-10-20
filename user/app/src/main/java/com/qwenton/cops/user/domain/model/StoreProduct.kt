package com.qwenton.cops.user.domain.model

data class StoreProductVariant(
    val id: String = "",
    val name: String = "",
    val priceDeltaPaise: Long = 0L,
    val stock: Int = 0
)

/**
 * Public Customer View of a Product.
 * Strictly omits seller productCost, packagingCost, shippingCost, and return assumptions
 * to guarantee complete privacy and zero margin leakage.
 */
data class StoreProduct(
    val id: String = "",
    val businessId: String = "",
    val businessName: String = "",
    val sellerWhatsapp: String = "",
    val name: String = "",
    val description: String = "",
    val currency: String = "INR",
    val sellingPricePaise: Long = 0L,
    val discountPaise: Long = 0L,
    val images: List<String> = emptyList(),
    val variants: List<StoreProductVariant> = emptyList(),
    val stockQuantity: Int = 0,
    val isActive: Boolean = true
) {
    val effectivePricePaise: Long
        get() = (sellingPricePaise - discountPaise).coerceAtLeast(0L)

    val effectivePriceRupees: Double
        get() = effectivePricePaise / 100.0

    fun formatPrice(paise: Long = effectivePricePaise): String {
        return String.format("₹%,.2f", paise / 100.0)
    }
}
