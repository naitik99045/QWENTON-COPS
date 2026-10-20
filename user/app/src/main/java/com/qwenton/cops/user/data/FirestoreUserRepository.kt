package com.qwenton.cops.user.data

import com.google.firebase.firestore.FirebaseFirestore
import com.qwenton.cops.user.domain.model.StoreProduct
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await

data class CustomerOrderState(
    val orderId: String = "",
    val orderNumber: String = "",
    val paymentStatus: String = "pending",
    val fulfilmentStatus: String = "payment_pending",
    val famgatewayTxnId: String? = null,
    val famgatewayUtr: String? = null,
    val trackingNumber: String? = null,
    val courierName: String? = null
)

class FirestoreUserRepository(
    private val firestore: FirebaseFirestore = FirebaseFirestore.getInstance()
) {

    /**
     * Observes public catalog products (zero-cost leak protection)
     */
    fun observePublicCatalog(): Flow<List<StoreProduct>> = callbackFlow {
        val listener = firestore.collection("products")
            .whereEqualTo("isActive", true)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    close(error)
                    return@addSnapshotListener
                }
                if (snapshot != null) {
                    val products = snapshot.documents.mapNotNull { doc ->
                        // Safely extract only customer-safe public attributes
                        StoreProduct(
                            id = doc.id,
                            businessId = doc.getString("businessId") ?: "",
                            name = doc.getString("name") ?: "",
                            description = doc.getString("description") ?: "",
                            currency = doc.getString("currency") ?: "INR",
                            sellingPricePaise = doc.getLong("sellingPricePaise") ?: 0L,
                            discountPaise = doc.getLong("discountPaise") ?: 0L,
                            images = (doc.get("images") as? List<*>)?.filterIsInstance<String>() ?: emptyList(),
                            stockQuantity = doc.getLong("stockQuantity")?.toInt() ?: 0,
                            isActive = doc.getBoolean("isActive") ?: true
                        )
                    }
                    trySend(products)
                }
            }

        awaitClose { listener.remove() }
    }

    /**
     * Customer creates initial order
     */
    suspend fun createInitialOrder(
        orderId: String,
        orderNumber: String,
        businessId: String,
        customerId: String,
        customerName: String,
        customerPhone: String,
        deliveryAddress: String,
        pincode: String,
        city: String,
        state: String,
        productName: String,
        quantity: Int,
        totalPaise: Long,
        paymentMethod: String = "famgateway"
    ): Result<Unit> = runCatching {
        val timestamp = java.time.Instant.now().toString()
        val orderMap = mapOf(
            "id" to orderId,
            "orderNumber" to orderNumber,
            "businessId" to businessId,
            "customerId" to customerId,
            "customerName" to customerName,
            "customerPhone" to customerPhone,
            "deliveryAddress" to deliveryAddress,
            "pincode" to pincode,
            "city" to city,
            "state" to state,
            "paymentMethod" to paymentMethod,
            "paymentStatus" to "pending",
            "fulfilmentStatus" to "payment_pending",
            "subtotalPaise" to totalPaise,
            "discountPaise" to 0L,
            "netSalesPaise" to totalPaise,
            // Seller internal cost assumptions populated by Firestore triggers / business defaults
            "productCostPaise" to (totalPaise * 0.4).toLong(),
            "packagingCostPaise" to 1500L,
            "shippingPaise" to 6000L,
            "paymentFeePaise" to (totalPaise * 0.02).toLong(),
            "estimatedProfitPaise" to (totalPaise * 0.45).toLong(),
            "createdAt" to timestamp,
            "updatedAt" to timestamp
        )

        firestore.collection("orders").document(orderId).set(orderMap).await()
    }

    /**
     * Real-time listener for order status changes.
     * Fires immediately when FamGateway webhook completes and marks the order as paid!
     */
    fun observeOrderStatus(orderId: String): Flow<CustomerOrderState?> = callbackFlow {
        val listener = firestore.collection("orders").document(orderId)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    close(error)
                    return@addSnapshotListener
                }

                if (snapshot != null && snapshot.exists()) {
                    val state = CustomerOrderState(
                        orderId = snapshot.id,
                        orderNumber = snapshot.getString("orderNumber") ?: "",
                        paymentStatus = snapshot.getString("paymentStatus") ?: "pending",
                        fulfilmentStatus = snapshot.getString("fulfilmentStatus") ?: "payment_pending",
                        famgatewayTxnId = snapshot.getString("famgatewayTxnId"),
                        famgatewayUtr = snapshot.getString("famgatewayUtr"),
                        trackingNumber = snapshot.getString("trackingNumber"),
                        courierName = snapshot.getString("courierName")
                    )
                    trySend(state)
                } else {
                    trySend(null)
                }
            }

        awaitClose { listener.remove() }
    }
}
