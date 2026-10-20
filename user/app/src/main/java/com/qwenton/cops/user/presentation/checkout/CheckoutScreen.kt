package com.qwenton.cops.user.presentation.checkout

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.qwenton.cops.user.data.FirestoreUserRepository
import com.qwenton.cops.user.domain.model.StoreProduct
import com.qwenton.cops.user.domain.model.StoreProductVariant
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CheckoutScreen(
    product: StoreProduct,
    variant: StoreProductVariant?,
    quantity: Int,
    customerId: String,
    onBack: () -> Unit,
    onProceedToPayment: (orderId: String, orderNumber: String, totalPaise: Long, customerName: String, customerPhone: String, paymentMethod: String) -> Unit,
    userRepository: FirestoreUserRepository = remember { FirestoreUserRepository() }
) {
    val coroutineScope = rememberCoroutineScope()

    var customerName by remember { mutableStateOf("Pooja Sharma") }
    var customerPhone by remember { mutableStateOf("9811223344") }
    var deliveryAddress by remember { mutableStateOf("Flat 402, Lotus Heights, Malviya Nagar") }
    var pincode by remember { mutableStateOf("302017") }
    var city by remember { mutableStateOf("Jaipur") }
    var state by remember { mutableStateOf("Rajasthan") }
    var paymentMethod by remember { mutableStateOf("famgateway") } // "famgateway" or "cod"

    var isSubmitting by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    val unitPricePaise = product.effectivePricePaise + (variant?.priceDeltaPaise ?: 0L)
    val totalPaise = unitPricePaise * quantity

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Checkout & Delivery", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.White)
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp)
        ) {
            // Order Summary Card
            Card(
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(product.name, fontWeight = FontWeight.Bold, fontSize = 15.sp)
                    if (variant != null) {
                        Text(variant.name, color = Color(0xFF1877F2), fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
                    }
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("Qty: $quantity", color = Color.Gray, fontSize = 13.sp)
                        Text(String.format("₹%,.2f", totalPaise / 100.0), fontWeight = FontWeight.Bold, fontSize = 16.sp)
                    }
                }
            }

            Spacer(modifier = Modifier.height(18.dp))
            Text("Shipping & Delivery Details", fontWeight = FontWeight.Bold, fontSize = 16.sp)
            Spacer(modifier = Modifier.height(8.dp))

            if (errorMessage != null) {
                Text(errorMessage ?: "", color = Color.Red, fontSize = 12.sp)
                Spacer(modifier = Modifier.height(8.dp))
            }

            OutlinedTextField(
                value = customerName,
                onValueChange = { customerName = it },
                label = { Text("Full Name") },
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(8.dp))

            OutlinedTextField(
                value = customerPhone,
                onValueChange = { customerPhone = it },
                label = { Text("Mobile Number (10 digits)") },
                prefix = { Text("+91 ") },
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(8.dp))

            OutlinedTextField(
                value = deliveryAddress,
                onValueChange = { deliveryAddress = it },
                label = { Text("Street Address / House No") },
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(8.dp))

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(
                    value = pincode,
                    onValueChange = { pincode = it },
                    label = { Text("Pincode") },
                    modifier = Modifier.weight(1f)
                )
                OutlinedTextField(
                    value = city,
                    onValueChange = { city = it },
                    label = { Text("City") },
                    modifier = Modifier.weight(1f)
                )
            }

            Spacer(modifier = Modifier.height(20.dp))
            Text("Select Payment Method", fontWeight = FontWeight.Bold, fontSize = 16.sp)
            Spacer(modifier = Modifier.height(8.dp))

            // FamGateway UPI Option
            Card(
                shape = RoundedCornerShape(10.dp),
                colors = CardDefaults.cardColors(
                    containerColor = if (paymentMethod == "famgateway") Color(0xFFEFF6FF) else Color.White
                ),
                border = androidx.compose.foundation.BorderStroke(
                    1.dp,
                    if (paymentMethod == "famgateway") Color(0xFF1877F2) else Color(0xFFE2E8F0)
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { paymentMethod = "famgateway" }
            ) {
                Row(
                    modifier = Modifier.padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    RadioButton(
                        selected = paymentMethod == "famgateway",
                        onClick = { paymentMethod = "famgateway" }
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Column {
                        Text("FamGateway UPI Instant Payment", fontWeight = FontWeight.Bold, fontSize = 14.sp)
                        Text("Pay via Google Pay, PhonePe, Paytm, or BHIM", color = Color.Gray, fontSize = 12.sp)
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // COD Option
            Card(
                shape = RoundedCornerShape(10.dp),
                colors = CardDefaults.cardColors(
                    containerColor = if (paymentMethod == "cod") Color(0xFFEFF6FF) else Color.White
                ),
                border = androidx.compose.foundation.BorderStroke(
                    1.dp,
                    if (paymentMethod == "cod") Color(0xFF1877F2) else Color(0xFFE2E8F0)
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { paymentMethod = "cod" }
            ) {
                Row(
                    modifier = Modifier.padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    RadioButton(
                        selected = paymentMethod == "cod",
                        onClick = { paymentMethod = "cod" }
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Column {
                        Text("Cash on Delivery (COD)", fontWeight = FontWeight.Bold, fontSize = 14.sp)
                        Text("Pay cash to the delivery courier partner", color = Color.Gray, fontSize = 12.sp)
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            Button(
                onClick = {
                    if (customerName.isBlank() || customerPhone.length < 10 || deliveryAddress.isBlank() || pincode.isBlank()) {
                        errorMessage = "Please complete all delivery fields"
                        return@Button
                    }
                    errorMessage = null
                    isSubmitting = true

                    val orderId = "ord_${System.currentTimeMillis()}"
                    val orderNumber = "QC-${System.currentTimeMillis().toString().takeLast(8)}"

                    coroutineScope.launch {
                        userRepository.createInitialOrder(
                            orderId = orderId,
                            orderNumber = orderNumber,
                            businessId = product.businessId,
                            customerId = customerId,
                            customerName = customerName,
                            customerPhone = customerPhone,
                            deliveryAddress = deliveryAddress,
                            pincode = pincode,
                            city = city,
                            state = state,
                            productName = product.name,
                            quantity = quantity,
                            totalPaise = totalPaise,
                            paymentMethod = paymentMethod
                        )

                        isSubmitting = false
                        onProceedToPayment(orderId, orderNumber, totalPaise, customerName, customerPhone, paymentMethod)
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1877F2)),
                enabled = !isSubmitting
            ) {
                if (isSubmitting) {
                    CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
                } else {
                    Icon(Icons.Default.Lock, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        if (paymentMethod == "famgateway") "Proceed to FamGateway UPI" else "Confirm Cash on Delivery Order",
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp
                    )
                }
            }
        }
    }
}
