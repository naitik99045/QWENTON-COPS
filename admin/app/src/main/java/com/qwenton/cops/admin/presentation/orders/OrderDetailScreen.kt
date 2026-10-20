package com.qwenton.cops.admin.presentation.orders

import android.content.Context
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.qwenton.cops.admin.data.FirestoreAdminRepository
import com.qwenton.cops.admin.domain.model.Order
import com.qwenton.cops.admin.presentation.whatsapp.WhatsAppActionSheet
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OrderDetailScreen(
    order: Order,
    onBack: () -> Unit,
    repository: FirestoreAdminRepository = remember { FirestoreAdminRepository() }
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()

    var showWhatsAppSheet by remember { mutableStateOf(false) }
    var showShippingDialog by remember { mutableStateOf(false) }
    var showCostAdjustmentDialog by remember { mutableStateOf(false) }
    var currentOrder by remember { mutableStateOf(order) }

    // Shipping Dialog State
    var courierName by remember { mutableStateOf(order.courierName ?: "Delhivery") }
    var trackingNumber by remember { mutableStateOf(order.trackingNumber ?: "") }

    // Cost Adjustment Dialog State
    var actualProductCostStr by remember { mutableStateOf((order.productCostPaise / 100).toString()) }
    var actualPackagingStr by remember { mutableStateOf((order.packagingCostPaise / 100).toString()) }
    var actualShippingStr by remember { mutableStateOf((order.shippingPaise / 100).toString()) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Order #${currentOrder.orderNumber}", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = { showWhatsAppSheet = true }) {
                        Icon(Icons.Default.Send, contentDescription = "WhatsApp", tint = Color(0xFF16A34A))
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
            // Operational Stepper / Status Banner
            Card(
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Current Fulfilment Status", color = Color.Gray, fontSize = 12.sp)
                        AssistChip(
                            onClick = {},
                            label = { Text(currentOrder.fulfilmentStatus.uppercase(), fontWeight = FontWeight.Bold, fontSize = 11.sp) }
                        )
                    }

                    if (currentOrder.trackingNumber != null) {
                        Spacer(modifier = Modifier.height(10.dp))
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Share, contentDescription = null, tint = Color(0xFF1877F2), modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                "${currentOrder.courierName}: ${currentOrder.trackingNumber}",
                                fontWeight = FontWeight.Bold,
                                fontSize = 13.sp,
                                color = Color(0xFF1877F2)
                            )
                        }
                    }

                    if (currentOrder.famgatewayUtr != null) {
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            "FamGateway UTR: ${currentOrder.famgatewayUtr} (Verified)",
                            color = Color(0xFF16A34A),
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 12.sp
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // TRUE PROFIT ANATOMY CARD
            Card(
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(containerColor = Color(0xFF0F172A)),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(18.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("TRUE PROFIT ANATOMY", color = Color(0xFF94A3B8), fontSize = 11.sp, fontWeight = FontWeight.Bold)
                        TextButton(
                            onClick = { showCostAdjustmentDialog = true },
                            contentPadding = PaddingValues(0.dp)
                        ) {
                            Text("Adjust Costs", color = Color(0xFF38BDF8), fontSize = 12.sp)
                        }
                    }

                    val profitToDisplay = currentOrder.realisedProfitPaise ?: currentOrder.estimatedProfitPaise
                    val isLoss = profitToDisplay < 0

                    Text(
                        text = String.format("₹%,.2f", profitToDisplay / 100.0),
                        color = if (isLoss) Color(0xFFF87171) else Color(0xFF4ADE80),
                        fontSize = 32.sp,
                        fontWeight = FontWeight.Black
                    )

                    Text(
                        text = if (currentOrder.realisedProfitPaise != null) "Realised Final Profit" else "Estimated Contribution Margin",
                        color = Color(0xFF94A3B8),
                        fontSize = 12.sp
                    )

                    Spacer(modifier = Modifier.height(12.dp))
                    Divider(color = Color(0xFF334155))
                    Spacer(modifier = Modifier.height(12.dp))

                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text("Net Customer Revenue", color = Color(0xFF94A3B8), fontSize = 12.sp)
                        Text(currentOrder.formatRupees(currentOrder.netSalesPaise), color = Color.White, fontWeight = FontWeight.SemiBold, fontSize = 12.sp)
                    }
                    Spacer(modifier = Modifier.height(4.dp))
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text("Product Wholesale COGS", color = Color(0xFF94A3B8), fontSize = 12.sp)
                        Text("-${currentOrder.formatRupees(currentOrder.productCostPaise)}", color = Color(0xFFCBD5E1), fontSize = 12.sp)
                    }
                    Spacer(modifier = Modifier.height(4.dp))
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text("Packaging Overhead", color = Color(0xFF94A3B8), fontSize = 12.sp)
                        Text("-${currentOrder.formatRupees(currentOrder.packagingCostPaise)}", color = Color(0xFFCBD5E1), fontSize = 12.sp)
                    }
                    Spacer(modifier = Modifier.height(4.dp))
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text("Courier Shipping", color = Color(0xFF94A3B8), fontSize = 12.sp)
                        Text("-${currentOrder.formatRupees(currentOrder.shippingPaise)}", color = Color(0xFFCBD5E1), fontSize = 12.sp)
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Customer Details Card
            Card(
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Customer & Delivery Address", fontWeight = FontWeight.Bold, fontSize = 14.sp)
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(currentOrder.customerName, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
                    Text("+91 ${currentOrder.customerPhone}", color = Color.Gray, fontSize = 13.sp)
                    Spacer(modifier = Modifier.height(4.dp))
                    Text("${currentOrder.deliveryAddress}, ${currentOrder.city} - ${currentOrder.pincode}", color = Color.DarkGray, fontSize = 12.sp)
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // FULFILMENT ACTION BUTTONS
            when (currentOrder.fulfilmentStatus) {
                "to_pack" -> {
                    Button(
                        onClick = {
                            coroutineScope.launch {
                                repository.updateFulfilmentStatus(currentOrder.id, "packed")
                                currentOrder = currentOrder.copy(fulfilmentStatus = "packed")
                            }
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(50.dp),
                        shape = RoundedCornerShape(10.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1877F2))
                    ) {
                        Icon(Icons.Default.Check, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Mark Parcel as Packed", fontWeight = FontWeight.Bold)
                    }
                }
                "packed" -> {
                    Button(
                        onClick = { showShippingDialog = true },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(50.dp),
                        shape = RoundedCornerShape(10.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF0F172A))
                    ) {
                        Icon(Icons.Default.Send, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Add Tracking & Mark Shipped", fontWeight = FontWeight.Bold)
                    }
                }
                "shipped" -> {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Button(
                            onClick = {
                                coroutineScope.launch {
                                    repository.updateFulfilmentStatus(currentOrder.id, "delivered")
                                    currentOrder = currentOrder.copy(fulfilmentStatus = "delivered")
                                }
                            },
                            modifier = Modifier
                                .weight(1f)
                                .height(50.dp),
                            shape = RoundedCornerShape(10.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF16A34A))
                        ) {
                            Text("Mark Delivered", fontWeight = FontWeight.Bold)
                        }

                        OutlinedButton(
                            onClick = {
                                coroutineScope.launch {
                                    repository.updateFulfilmentStatus(currentOrder.id, "rto")
                                    currentOrder = currentOrder.copy(fulfilmentStatus = "rto")
                                }
                            },
                            modifier = Modifier
                                .weight(1f)
                                .height(50.dp),
                            shape = RoundedCornerShape(10.dp),
                            colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFFDC2626))
                        ) {
                            Text("Mark RTO Loss", fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
        }
    }

    // WhatsApp Action Sheet
    if (showWhatsAppSheet) {
        WhatsAppActionSheet(
            context = context,
            order = currentOrder,
            onDismiss = { showWhatsAppSheet = false }
        )
    }

    // Add Shipping / Courier Dialog
    if (showShippingDialog) {
        AlertDialog(
            onDismissRequest = { showShippingDialog = false },
            title = { Text("Add Courier & Dispatch", fontWeight = FontWeight.Bold) },
            text = {
                Column {
                    OutlinedTextField(
                        value = courierName,
                        onValueChange = { courierName = it },
                        label = { Text("Courier Partner") },
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(modifier = Modifier.height(10.dp))
                    OutlinedTextField(
                        value = trackingNumber,
                        onValueChange = { trackingNumber = it },
                        label = { Text("AWB / Tracking Number") },
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                Button(onClick = {
                    showShippingDialog = false
                    coroutineScope.launch {
                        repository.updateFulfilmentStatus(
                            orderId = currentOrder.id,
                            newStatus = "shipped",
                            courierName = courierName,
                            trackingNumber = trackingNumber
                        )
                        currentOrder = currentOrder.copy(
                            fulfilmentStatus = "shipped",
                            courierName = courierName,
                            trackingNumber = trackingNumber
                        )
                    }
                }) {
                    Text("Confirm Dispatch")
                }
            },
            dismissButton = {
                TextButton(onClick = { showShippingDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    // Cost Recalculation Dialog
    if (showCostAdjustmentDialog) {
        AlertDialog(
            onDismissRequest = { showCostAdjustmentDialog = false },
            title = { Text("Adjust Order Costs", fontWeight = FontWeight.Bold) },
            text = {
                Column {
                    OutlinedTextField(
                        value = actualProductCostStr,
                        onValueChange = { actualProductCostStr = it },
                        label = { Text("Actual COGS (₹)") },
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = actualPackagingStr,
                        onValueChange = { actualPackagingStr = it },
                        label = { Text("Actual Packaging (₹)") },
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = actualShippingStr,
                        onValueChange = { actualShippingStr = it },
                        label = { Text("Actual Shipping (₹)") },
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                Button(onClick = {
                    showCostAdjustmentDialog = false
                    val newCogs = ((actualProductCostStr.toDoubleOrNull() ?: 0.0) * 100).toLong()
                    val newPackaging = ((actualPackagingStr.toDoubleOrNull() ?: 0.0) * 100).toLong()
                    val newShipping = ((actualShippingStr.toDoubleOrNull() ?: 0.0) * 100).toLong()

                    coroutineScope.launch {
                        repository.recalculateOrderCosts(
                            orderId = currentOrder.id,
                            newProductCostPaise = newCogs,
                            newPackagingCostPaise = newPackaging,
                            newShippingPaise = newShipping
                        )
                        currentOrder = currentOrder.copy(
                            productCostPaise = newCogs,
                            packagingCostPaise = newPackaging,
                            shippingPaise = newShipping
                        )
                    }
                }) {
                    Text("Recalculate Profit")
                }
            },
            dismissButton = {
                TextButton(onClick = { showCostAdjustmentDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}
