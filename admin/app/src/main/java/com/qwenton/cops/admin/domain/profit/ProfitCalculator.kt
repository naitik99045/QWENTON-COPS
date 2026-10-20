package com.qwenton.cops.admin.domain.profit

/**
 * Pure Kotlin Dual-Engine Profit Calculator for Indian Social Sellers.
 * Operates strictly on Integer Minor Units (Paise, 1 INR = 100 Paise)
 * to avoid floating-point rounding bleed.
 */
object ProfitCalculator {

    data class ExpectedProfitResult(
        val netSalesPaise: Long,
        val paymentFeePaise: Long,
        val expectedReturnCostPaise: Long,
        val expectedRtoCostPaise: Long,
        val estimatedProfitPaise: Long,
        val marginPercentage: Double
    )

    data class RealisedProfitResult(
        val realisedProfitPaise: Long,
        val isLoss: Boolean,
        val marginPercentage: Double
    )

    /**
     * Calculates the Estimated Contribution Margin at the time of order creation.
     */
    fun calculateEstimatedProfit(
        sellingPricePaise: Long,
        discountPaise: Long = 0L,
        productCostPaise: Long,
        packagingCostPaise: Long,
        shippingCostPaise: Long,
        paymentFeeRate: Double = 0.02, // 2% gateway fee
        expectedReturnRate: Double = 5.0, // 5%
        expectedRtoRate: Double = 10.0 // 10%
    ): ExpectedProfitResult {
        val netSales = (sellingPricePaise - discountPaise).coerceAtLeast(0L)
        val paymentFee = (netSales * paymentFeeRate).toLong()

        // Risk allocations for Indian social commerce:
        // Expected return cost considers reverse courier and repackaging (~25% of net sales)
        val expectedReturnCost = (netSales * (expectedReturnRate / 100.0) * 0.25).toLong()

        // RTO incurs both forward shipping and reverse courier charges
        val expectedRtoCost = ((shippingCostPaise * 2) * (expectedRtoRate / 100.0)).toLong()

        val totalCosts = productCostPaise + packagingCostPaise + shippingCostPaise +
                paymentFee + expectedReturnCost + expectedRtoCost

        val estimatedProfit = netSales - totalCosts
        val marginPercentage = if (netSales > 0) {
            (estimatedProfit.toDouble() / netSales.toDouble()) * 100.0
        } else 0.0

        return ExpectedProfitResult(
            netSalesPaise = netSales,
            paymentFeePaise = paymentFee,
            expectedReturnCostPaise = expectedReturnCost,
            expectedRtoCostPaise = expectedRtoCost,
            estimatedProfitPaise = estimatedProfit,
            marginPercentage = marginPercentage
        )
    }

    /**
     * Calculates Realised Profit once an order reaches a terminal state.
     */
    fun calculateRealisedProfit(
        fulfilmentStatus: String, // "delivered", "rto", "returned", "cancelled"
        settlementReceivedPaise: Long,
        actualProductCostPaise: Long,
        actualPackagingCostPaise: Long,
        actualForwardShippingPaise: Long,
        actualReverseShippingPaise: Long = 0L,
        actualGatewayFeePaise: Long = 0L
    ): RealisedProfitResult {
        val profit: Long = when (fulfilmentStatus.lowercase()) {
            "delivered" -> {
                settlementReceivedPaise - actualProductCostPaise - actualPackagingCostPaise -
                        actualForwardShippingPaise - actualGatewayFeePaise
            }
            "rto" -> {
                // In RTO: Zero revenue received, product returned to inventory,
                // but seller absorbs packaging + forward courier + reverse courier!
                0L - actualPackagingCostPaise - actualForwardShippingPaise - actualReverseShippingPaise
            }
            "returned" -> {
                // Customer return: refund issued, absorbs reverse pickup & packaging
                0L - actualPackagingCostPaise - actualForwardShippingPaise -
                        actualReverseShippingPaise - actualGatewayFeePaise
            }
            "cancelled" -> 0L
            else -> {
                // Fallback to contribution estimate
                settlementReceivedPaise - actualProductCostPaise - actualPackagingCostPaise - actualForwardShippingPaise
            }
        }

        val margin = if (settlementReceivedPaise > 0) {
            (profit.toDouble() / settlementReceivedPaise.toDouble()) * 100.0
        } else {
            if (profit < 0) -100.0 else 0.0
        }

        return RealisedProfitResult(
            realisedProfitPaise = profit,
            isLoss = profit < 0,
            marginPercentage = margin
        )
    }
}
