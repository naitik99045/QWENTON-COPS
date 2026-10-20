package com.qwenton.cops.admin.domain.model

data class Business(
    val id: String = "",
    val ownerUserId: String = "",
    val name: String = "",
    val preferredLanguage: String = "hi",
    val whatsappNumber: String = "",
    val defaultShippingCostPaise: Long = 6000L,   // ₹60
    val defaultPackagingCostPaise: Long = 1500L,  // ₹15
    val defaultReturnRate: Double = 8.0,          // 8%
    val defaultRtoRate: Double = 12.0,            // 12%
    val isActive: Boolean = true,
    val createdAt: String = ""
)
