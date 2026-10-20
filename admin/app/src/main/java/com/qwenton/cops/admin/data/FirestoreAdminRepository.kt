package com.qwenton.cops.admin.data

import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import com.qwenton.cops.admin.domain.model.Order
import com.qwenton.cops.admin.domain.model.Product
import com.qwenton.cops.admin.domain.profit.ProfitCalculator
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await

class FirestoreAdminRepository(
    private val firestore: FirebaseFirestore = FirebaseFirestore.getInstance()
) {

    /**
     * Real-time stream of all orders for a given business.
     * Automatically updates whenever a FamGateway webhook triggers payment.
     */
    fun observeOrders(businessId: String): Flow<List<Order>> = callbackFlow {
        val query = firestore.collection("orders")
            .whereEqualTo("businessId", businessId)
            .orderBy("createdAt", Query.Direction.DESCENDING)

        val listener = query.addSnapshotListener { snapshot, error ->
            if (error != null) {
                close(error)
                return@addSnapshotListener
            }

            if (snapshot != null) {
                val orders = snapshot.toObjects(Order::class.java)
                trySend(orders)
            }
        }

        awaitClose { listener.remove() }
    }

    /**
     * Transition order fulfilment state (e.g., to_pack -> packed -> shipped -> delivered / rto)
     */
    suspend fun updateFulfilmentStatus(
        orderId: String,
        newStatus: String,
        courierName: String? = null,
        trackingNumber: String? = null
    ): Result<Unit> = runCatching {
        val updates = mutableMapOf<String, Any>(
            "fulfilmentStatus" to newStatus,
            "updatedAt" to java.time.Instant.now().toString()
        )

        courierName?.let { updates["courierName"] = it }
        trackingNumber?.let { updates["trackingNumber"] = it }

        // If order reaches terminal state (delivered, rto), update realised profit
        val doc = firestore.collection("orders").document(orderId).get().await()
        val order = doc.toObject(Order::class.java)

        if (order != null && (newStatus == "delivered" || newStatus == "rto")) {
            val realised = ProfitCalculator.calculateRealisedProfit(
                fulfilmentStatus = newStatus,
                settlementReceivedPaise = if (newStatus == "delivered") order.netSalesPaise else 0L,
                actualProductCostPaise = order.productCostPaise,
                actualPackagingCostPaise = order.packagingCostPaise,
                actualForwardShippingPaise = order.shippingPaise,
                actualReverseShippingPaise = if (newStatus == "rto") order.shippingPaise else 0L,
                actualGatewayFeePaise = order.paymentFeePaise
            )
            updates["realisedProfitPaise"] = realised.realisedProfitPaise
        }

        firestore.collection("orders").document(orderId).update(updates).await()
    }

    /**
     * Update internal order cost assumptions and recalculate profit
     */
    suspend fun recalculateOrderCosts(
        orderId: String,
        newProductCostPaise: Long,
        newPackagingCostPaise: Long,
        newShippingPaise: Long
    ): Result<Unit> = runCatching {
        val doc = firestore.collection("orders").document(orderId).get().await()
        val order = doc.toObject(Order::class.java) ?: return@runCatching

        val profitResult = ProfitCalculator.calculateEstimatedProfit(
            sellingPricePaise = order.subtotalPaise,
            discountPaise = order.discountPaise,
            productCostPaise = newProductCostPaise,
            packagingCostPaise = newPackagingCostPaise,
            shippingCostPaise = newShippingPaise
        )

        firestore.collection("orders").document(orderId).update(
            mapOf(
                "productCostPaise" to newProductCostPaise,
                "packagingCostPaise" to newPackagingCostPaise,
                "shippingPaise" to newShippingPaise,
                "estimatedProfitPaise" to profitResult.estimatedProfitPaise,
                "updatedAt" to java.time.Instant.now().toString()
            )
        ).await()
    }

    /**
     * Real-time stream of products
     */
    fun observeProducts(businessId: String): Flow<List<Product>> = callbackFlow {
        val listener = firestore.collection("products")
            .whereEqualTo("businessId", businessId)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    close(error)
                    return@addSnapshotListener
                }
                if (snapshot != null) {
                    trySend(snapshot.toObjects(Product::class.java))
                }
            }

        awaitClose { listener.remove() }
    }

    /**
     * Save or update product
     */
    suspend fun saveProduct(product: Product): Result<Unit> = runCatching {
        val id = product.id.ifBlank { firestore.collection("products").document().id }
        val updated = product.copy(id = id)
        firestore.collection("products").document(id).set(updated).await()
    }
}
