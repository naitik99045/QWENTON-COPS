package com.qwenton.cops.admin.presentation.settings

import android.content.Context
import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.qwenton.cops.admin.domain.model.Business
import com.qwenton.cops.admin.domain.model.Order

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    business: Business,
    orders: List<Order>,
    onSignOut: () -> Unit
) {
    val context = LocalContext.current
    var showDeleteAccountDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Settings & DPDP Compliance", fontWeight = FontWeight.Bold) },
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
            // Profile Card
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
                        Text(business.name, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                        AssistChip(
                            onClick = {},
                            label = { Text("Store Owner", fontWeight = FontWeight.Bold, color = Color(0xFF1877F2)) }
                        )
                    }
                    Spacer(modifier = Modifier.height(4.dp))
                    Text("WhatsApp: ${business.whatsappNumber}", color = Color.Gray, fontSize = 13.sp)
                    Text("Backend Host: qwen.qwenton.shop", color = Color(0xFF16A34A), fontSize = 12.sp, fontWeight = FontWeight.Medium)
                }
            }

            Spacer(modifier = Modifier.height(20.dp))
            Text("Accounting & Financial Exports", fontWeight = FontWeight.Bold, fontSize = 16.sp)
            Text("RFC 4180 format compatible with Tally ERP, Zoho Books, and Excel.", color = Color.Gray, fontSize = 12.sp)

            Spacer(modifier = Modifier.height(10.dp))

            // Export Orders CSV Button
            OutlinedButton(
                onClick = {
                    val csvContent = buildOrdersCsv(orders)
                    shareCsv(context, "Qwenton_Orders_Financial_Export.csv", csvContent)
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                shape = RoundedCornerShape(10.dp)
            ) {
                Icon(Icons.Default.Share, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(modifier = Modifier.width(8.dp))
                Text("Export Orders Financial CSV (${orders.size} Records)")
            }

            Spacer(modifier = Modifier.height(24.dp))
            Divider()
            Spacer(modifier = Modifier.height(18.dp))

            // DPDP Act Compliance Card
            Card(
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = Color(0xFFFEF2F2)),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.Warning, contentDescription = null, tint = Color(0xFFDC2626), modifier = Modifier.size(20.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            "Digital Personal Data Protection (DPDP) Act 2023",
                            fontWeight = FontWeight.Bold,
                            color = Color(0xFF991B1B),
                            fontSize = 13.sp
                        )
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        "Under Indian DPDP Act, customers and fiduciaries possess the right to data portability and complete erasure of personal records.",
                        color = Color(0xFF7F1D1D),
                        fontSize = 12.sp,
                        lineHeight = 16.sp
                    )

                    Spacer(modifier = Modifier.height(14.dp))

                    Button(
                        onClick = { showDeleteAccountDialog = true },
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFDC2626)),
                        shape = RoundedCornerShape(8.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(Icons.Default.Delete, contentDescription = null, tint = Color.White)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Permanently Erase Store & Customer Data")
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            TextButton(
                onClick = onSignOut,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Sign Out of Seller Session", color = Color.Gray)
            }
        }
    }

    if (showDeleteAccountDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteAccountDialog = false },
            icon = { Icon(Icons.Default.Warning, contentDescription = null, tint = Color.Red) },
            title = { Text("Irreversible Account Deletion?") },
            text = {
                Text(
                    "This action permanently deletes your business catalogue, orders, customer phone numbers, " +
                            "delivery addresses, and audit records in compliance with DPDP Act 2023. This cannot be undone."
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        showDeleteAccountDialog = false
                        onSignOut()
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = Color.Red)
                ) {
                    Text("Confirm Permanent Deletion")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteAccountDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

fun buildOrdersCsv(orders: List<Order>): String {
    val sb = StringBuilder()
    sb.append("Order Number,Customer Name,Customer Phone,Delivery Address,City,Pincode,Payment Mode,Payment Status,Fulfilment Status,Net Sales (INR),Product COGS (INR),Packaging (INR),Shipping (INR),Estimated Profit (INR),FamGateway Txn ID,FamGateway UTR\n")

    for (o in orders) {
        sb.append("\"${o.orderNumber}\",")
        sb.append("\"${o.customerName}\",")
        sb.append("\"${o.customerPhone}\",")
        sb.append("\"${o.deliveryAddress}\",")
        sb.append("\"${o.city}\",")
        sb.append("\"${o.pincode}\",")
        sb.append("\"${o.paymentMethod}\",")
        sb.append("\"${o.paymentStatus}\",")
        sb.append("\"${o.fulfilmentStatus}\",")
        sb.append("${o.netSalesPaise / 100.0},")
        sb.append("${o.productCostPaise / 100.0},")
        sb.append("${o.packagingCostPaise / 100.0},")
        sb.append("${o.shippingPaise / 100.0},")
        sb.append("${(o.realisedProfitPaise ?: o.estimatedProfitPaise) / 100.0},")
        sb.append("\"${o.famgatewayTxnId ?: ""}\",")
        sb.append("\"${o.famgatewayUtr ?: ""}\"\n")
    }

    return sb.toString()
}

fun shareCsv(context: Context, filename: String, csvContent: String) {
    val sendIntent = Intent().apply {
        action = Intent.ACTION_SEND
        putExtra(Intent.EXTRA_TEXT, csvContent)
        putExtra(Intent.EXTRA_TITLE, filename)
        type = "text/csv"
    }
    context.startActivity(Intent.createChooser(sendIntent, "Share Accounting CSV"))
}
