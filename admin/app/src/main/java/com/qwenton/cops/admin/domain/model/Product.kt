package com.qwenton.cops.admin.domain.model

data class ProductVariant(
    val id: String = "",
    val name: String = "",
    val priceDeltaPaise: Long = 0L,
    val stock: Int = 0
)

data class Product(
    val id: String = "",
    val businessId: String = "",
    val name: String = "",
    val description: String = "",
    val sku: String = "",
    val currency: String = "INR",
    val sellingPricePaise: Long = 0L,
    val discountPaise: Long = 0L,
    val productCostPaise: Long = 0L,     // Wholesale COGS
    val packagingCostPaise: Long = 0L,   // Packaging overhead
    val shippingCostPaise: Long = 0L,    // Forward courier cost
    val paymentFeeRate: Double = 0.02,   // 2% FamGateway fee
    val expectedReturnRate: Double = 5.0, // 5%
    val expectedRtoRate: Double = 10.0,   // 10%
    val stockQuantity: Int = 0,
    val images: List<String> = emptyList(),
    val variants: List<ProductVariant> = emptyList(),
    val isActive: Boolean = true,
    val createdAt: String = ""
)
