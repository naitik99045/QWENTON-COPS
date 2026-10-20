package com.qwenton.cops.user.data

import com.google.gson.Gson
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.util.concurrent.TimeUnit

data class CreatePaymentOrderRequest(
    val orderId: String,
    val amountMinor: Long,
    val customerName: String,
    val customerPhone: String,
    val businessId: String,
    val productName: String
)

data class CreatePaymentOrderResponse(
    val success: Boolean,
    val orderId: String,
    val famgatewayOrderId: String,
    val amountRupees: Double,
    val amountMinor: Long,
    val upiIntent: String,
    val paymentUrl: String,
    val webhookConfigured: String
)

class FamGatewayClient(
    private val baseUrl: String = "https://qwen.qwenton.shop"
) {
    private val client = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .build()

    private val gson = Gson()
    private val jsonMediaType = "application/json; charset=utf-8".toMediaType()

    /**
     * Calls Vercel Backend at https://qwen.qwenton.shop/api/famgateway/create-order
     * to initiate a payment session and retrieve the UPI Intent string.
     */
    suspend fun createPaymentOrder(
        request: CreatePaymentOrderRequest
    ): Result<CreatePaymentOrderResponse> = withContext(Dispatchers.IO) {
        runCatching {
            val jsonBody = gson.toJson(request)
            val httpRequest = Request.Builder()
                .url("$baseUrl/api/famgateway/create-order")
                .post(jsonBody.toRequestBody(jsonMediaType))
                .header("Content-Type", "application/json")
                .header("Accept", "application/json")
                .build()

            val response = client.newCall(httpRequest).execute()
            val responseBody = response.body?.string() ?: ""

            if (!response.isSuccessful) {
                throw Exception("Failed to create payment session: HTTP ${response.code} $responseBody")
            }

            gson.fromJson(responseBody, CreatePaymentOrderResponse::class.java)
        }
    }
}
