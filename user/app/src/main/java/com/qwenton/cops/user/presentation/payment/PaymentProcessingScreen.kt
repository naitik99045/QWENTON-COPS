package com.qwenton.cops.user.presentation.payment

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.qwenton.cops.user.data.CreatePaymentOrderRequest
import com.qwenton.cops.user.data.FamGatewayClient
import com.qwenton.cops.user.data.FirestoreUserRepository
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PaymentProcessingScreen(
    orderId: String,
    orderNumber: String,
    totalPaise: Long,
    customerName: String,
    customerPhone: String,
    businessId: String,
    onPaymentSuccess: (orderId: String, orderNumber: String) -> Unit,
    userRepository: FirestoreUserRepository = remember { FirestoreUserRepository() },
    famGatewayClient: FamGatewayClient = remember { FamGatewayClient(baseUrl = "https://qwen.qwenton.shop") }
) {
    val context = LocalContext.current
    val clipboardManager = LocalClipboardManager.current
    val coroutineScope = rememberCoroutineScope()

    var isInitiating by remember { mutableStateOf(true) }
    var upiIntentString by remember { mutableStateOf<String?>(null) }
    var paymentUrl by remember { mutableStateOf<String?>(null) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    // 1. Initiate FamGateway session via Vercel backend
    LaunchedEffect(orderId) {
        val result = famGatewayClient.createPaymentOrder(
            CreatePaymentOrderRequest(
                orderId = orderId,
                amountMinor = totalPaise,
                customerName = customerName,
                customerPhone = customerPhone,
                businessId = businessId,
                productName = "Storefront Order #$orderNumber"
            )
        )

        isInitiating = false

        result.onSuccess { response ->
            upiIntentString = response.upiIntent
            paymentUrl = response.paymentUrl

            // Auto-launch UPI Intent chooser if available
            try {
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(response.upiIntent))
                context.startActivity(intent)
            } catch (e: Exception) {
                // Device may lack registered UPI handlers or running on emulator
                Toast.makeText(context, "UPI intent ready. Please select an option below.", Toast.LENGTH_SHORT).show()
            }
        }.onFailure { err ->
            errorMessage = err.message ?: "Could not initiate FamGateway transaction"
        }
    }

    // 2. Real-time Firestore snapshot listener: watches for Webhook confirmation
    LaunchedEffect(orderId) {
        userRepository.observeOrderStatus(orderId).collect { state ->
            if (state != null && (state.paymentStatus == "paid" || state.fulfilmentStatus == "to_pack")) {
                onPaymentSuccess(orderId, orderNumber)
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("FamGateway UPI Checkout", fontWeight = FontWeight.Bold) },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.White)
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            if (isInitiating) {
                CircularProgressIndicator(color = Color(0xFF1877F2), modifier = Modifier.size(48.dp))
                Spacer(modifier = Modifier.height(16.dp))
                Text("Connecting to FamGateway Secure Session...", fontSize = 14.sp, color = Color.Gray)
                Text("Backend Host: qwen.qwenton.shop", fontSize = 12.sp, color = Color(0xFF16A34A), fontWeight = FontWeight.Medium)
            } else if (errorMessage != null) {
                Card(
                    colors = CardDefaults.cardColors(containerColor = Color(0xFFFEE2E2)),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text("Payment Initiation Issue", color = Color(0xFF991B1B), fontWeight = FontWeight.Bold)
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(errorMessage ?: "", color = Color(0xFF7F1D1D), fontSize = 12.sp)
                    }
                }
            } else {
                Card(
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = Color.White),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier.padding(20.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text("Order #${orderNumber}", fontWeight = FontWeight.Bold, fontSize = 16.sp)
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = String.format("₹%,.2f", totalPaise / 100.0),
                            fontSize = 32.sp,
                            fontWeight = FontWeight.Black,
                            color = Color(0xFF0F172A)
                        )
                        Spacer(modifier = Modifier.height(12.dp))

                        // Status Chip
                        Surface(
                            shape = RoundedCornerShape(6.dp),
                            color = Color(0xFFFEF3C7)
                        ) {
                            Text(
                                "Awaiting FamGateway Webhook Confirmation...",
                                color = Color(0xFF92400E),
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                            )
                        }

                        Spacer(modifier = Modifier.height(20.dp))

                        // Primary Action: Launch UPI Apps
                        Button(
                            onClick = {
                                if (upiIntentString != null) {
                                    try {
                                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(upiIntentString))
                                        context.startActivity(intent)
                                    } catch (e: Exception) {
                                        Toast.makeText(context, "No UPI app found on device", Toast.LENGTH_SHORT).show()
                                    }
                                }
                            },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(50.dp),
                            shape = RoundedCornerShape(10.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1877F2))
                        ) {
                            Icon(Icons.Default.Share, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Open in PhonePe / GPay / Paytm", fontWeight = FontWeight.Bold)
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        // Fallback: Copy VPA (UPI ID)
                        OutlinedButton(
                            onClick = {
                                clipboardManager.setText(AnnotatedString("famgateway@icici"))
                                Toast.makeText(context, "UPI ID copied: famgateway@icici", Toast.LENGTH_SHORT).show()
                            },
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(10.dp)
                        ) {
                            Text("Copy Merchant UPI ID (famgateway@icici)", fontSize = 12.sp)
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        // Dev simulator bypass button
                        TextButton(
                            onClick = {
                                onPaymentSuccess(orderId, orderNumber)
                            }
                        ) {
                            Text("⚡ Dev Simulator: Mark as Paid", fontSize = 12.sp, color = Color.Gray)
                        }
                    }
                }
            }
        }
    }
}
