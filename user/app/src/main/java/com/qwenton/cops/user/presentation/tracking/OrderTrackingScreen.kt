package com.qwenton.cops.user.presentation.tracking

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.qwenton.cops.user.data.CustomerOrderState
import com.qwenton.cops.user.data.FirestoreUserRepository
import java.net.URLEncoder

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OrderTrackingScreen(
    orderId: String,
    orderNumber: String,
    sellerWhatsapp: String = "919876543210",
    onBackToStore: () -> Unit,
    userRepository: FirestoreUserRepository = remember { FirestoreUserRepository() }
) {
    val context = LocalContext.current

    var orderState by remember {
        mutableStateOf(
            CustomerOrderState(
                orderId = orderId,
                orderNumber = orderNumber,
                paymentStatus = "paid",
                fulfilmentStatus = "to_pack",
                famgatewayUtr = "428901234567"
            )
        )
    }

    // Subscribe to live Firestore snapshot stream
    LaunchedEffect(orderId) {
        userRepository.observeOrderStatus(orderId).collect { state ->
            if (state != null) {
                orderState = state
            }
        }
    }

    val currentStep = when (orderState.fulfilmentStatus) {
        "payment_pending" -> 0
        "to_pack" -> 1
        "packed" -> 2
        "shipped" -> 3
        "delivered" -> 4
        else -> 1
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Track Order #${orderNumber}", fontWeight = FontWeight.Bold) },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.White)
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Default.CheckCircle,
                contentDescription = null,
                tint = Color(0xFF16A34A),
                modifier = Modifier.size(64.dp)
            )

            Spacer(modifier = Modifier.height(12.dp))
            Text("Order Confirmed & Live!", fontWeight = FontWeight.Black, fontSize = 22.sp)
            Text(
                "Realtime updates from seller & FamGateway webhook",
                color = Color.Gray,
                fontSize = 13.sp
            )

            Spacer(modifier = Modifier.height(24.dp))

            // LIVE TRACKING STEPPER CARD
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(20.dp)) {
                    Text("FULFILMENT PIPELINE", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color.Gray)
                    Spacer(modifier = Modifier.height(16.dp))

                    TrackingStepItem(
                        stepNumber = 1,
                        title = "Payment Confirmed",
                        subtitle = if (orderState.famgatewayUtr != null) "FamGateway UTR: ${orderState.famgatewayUtr}" else "Verified by Payment Gateway",
                        isDone = currentStep >= 1,
                        isActive = currentStep == 1
                    )

                    TrackingStepItem(
                        stepNumber = 2,
                        title = "Order Packed",
                        subtitle = "Seller has packed your items in standard packaging",
                        isDone = currentStep >= 2,
                        isActive = currentStep == 2
                    )

                    TrackingStepItem(
                        stepNumber = 3,
                        title = "Dispatched / In Transit",
                        subtitle = if (orderState.trackingNumber != null) "${orderState.courierName}: ${orderState.trackingNumber}" else "Courier partner assignment pending",
                        isDone = currentStep >= 3,
                        isActive = currentStep == 3
                    )

                    TrackingStepItem(
                        stepNumber = 4,
                        title = "Delivered to Doorstep",
                        subtitle = "Parcel handed over to customer",
                        isDone = currentStep >= 4,
                        isActive = currentStep == 4,
                        isLast = true
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Contact Seller on WhatsApp
            Button(
                onClick = {
                    val encoded = URLEncoder.encode("Hi, I would like an update on my order #$orderNumber", "UTF-8")
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://wa.me/$sellerWhatsapp?text=$encoded"))
                    context.startActivity(intent)
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF25D366))
            ) {
                Icon(Icons.Default.Send, contentDescription = null, tint = Color.White)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Chat with Seller on WhatsApp", fontWeight = FontWeight.Bold, color = Color.White)
            }

            Spacer(modifier = Modifier.height(12.dp))

            OutlinedButton(
                onClick = onBackToStore,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                shape = RoundedCornerShape(12.dp)
            ) {
                Icon(Icons.Default.Home, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Return to Storefront")
            }
        }
    }
}

@Composable
fun TrackingStepItem(
    stepNumber: Int,
    title: String,
    subtitle: String,
    isDone: Boolean,
    isActive: Boolean,
    isLast: Boolean = false
) {
    Row(modifier = Modifier.fillMaxWidth()) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Surface(
                shape = CircleShape,
                color = when {
                    isDone -> Color(0xFF16A34A)
                    isActive -> Color(0xFF1877F2)
                    else -> Color(0xFFE2E8F0)
                },
                modifier = Modifier.size(28.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    if (isDone) {
                        Icon(Icons.Default.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
                    } else {
                        Text("$stepNumber", color = if (isActive) Color.White else Color.Gray, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }

            if (!isLast) {
                Box(
                    modifier = Modifier
                        .width(2.dp)
                        .height(36.dp)
                        .background(if (isDone) Color(0xFF16A34A) else Color(0xFFE2E8F0))
                )
            }
        }

        Spacer(modifier = Modifier.width(14.dp))

        Column(modifier = Modifier.padding(bottom = if (isLast) 0.dp else 16.dp)) {
            Text(
                title,
                fontWeight = if (isDone || isActive) FontWeight.Bold else FontWeight.Medium,
                fontSize = 14.sp,
                color = if (isDone || isActive) Color(0xFF0F172A) else Color.Gray
            )
            Text(subtitle, fontSize = 12.sp, color = Color.Gray, lineHeight = 16.sp)
        }
    }
}
