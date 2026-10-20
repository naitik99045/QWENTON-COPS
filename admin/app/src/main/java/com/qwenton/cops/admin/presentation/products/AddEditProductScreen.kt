package com.qwenton.cops.admin.presentation.products

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.qwenton.cops.admin.data.FirestoreAdminRepository
import com.qwenton.cops.admin.domain.model.Product
import com.qwenton.cops.admin.domain.model.ProductVariant
import com.qwenton.cops.admin.domain.profit.ProfitCalculator
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddEditProductScreen(
    businessId: String,
    onBack: () -> Unit,
    onProductSaved: (Product) -> Unit,
    repository: FirestoreAdminRepository = remember { FirestoreAdminRepository() }
) {
    val coroutineScope = rememberCoroutineScope()

    var name by remember { mutableStateOf("Hand Embroidered Chikankari Kurti") }
    var description by remember { mutableStateOf("Pure modal cotton fabric with Lucknow hand embroidery.") }
    var sku by remember { mutableStateOf("CHK-KURTI-PNK") }
    var sellingPriceStr by remember { mutableStateOf("949") }
    var discountStr by remember { mutableStateOf("0") }
    var productCostStr by remember { mutableStateOf("420") }
    var packagingCostStr by remember { mutableStateOf("15") }
    var shippingCostStr by remember { mutableStateOf("60") }
    var stockStr by remember { mutableStateOf("45") }

    val variants = remember {
        mutableStateListOf(
            ProductVariant(id = "v1", name = "Size: S", priceDeltaPaise = 0L, stock = 10),
            ProductVariant(id = "v2", name = "Size: M", priceDeltaPaise = 0L, stock = 20),
            ProductVariant(id = "v3", name = "Size: L", priceDeltaPaise = 0L, stock = 15)
        )
    }

    var isSaving by remember { mutableStateOf(false) }

    // Live Math parsing
    val sellingPricePaise = ((sellingPriceStr.toDoubleOrNull() ?: 0.0) * 100).toLong()
    val discountPaise = ((discountStr.toDoubleOrNull() ?: 0.0) * 100).toLong()
    val productCostPaise = ((productCostStr.toDoubleOrNull() ?: 0.0) * 100).toLong()
    val packagingCostPaise = ((packagingCostStr.toDoubleOrNull() ?: 0.0) * 100).toLong()
    val shippingCostPaise = ((shippingCostStr.toDoubleOrNull() ?: 0.0) * 100).toLong()

    // Live True Profit Calculation Preview
    val profitPreview = remember(
        sellingPricePaise,
        discountPaise,
        productCostPaise,
        packagingCostPaise,
        shippingCostPaise
    ) {
        ProfitCalculator.calculateEstimatedProfit(
            sellingPricePaise = sellingPricePaise,
            discountPaise = discountPaise,
            productCostPaise = productCostPaise,
            packagingCostPaise = packagingCostPaise,
            shippingCostPaise = shippingCostPaise
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Add / Edit Product", fontWeight = FontWeight.Bold) },
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
            // LIVE MARGIN PREVIEW CARD
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(
                    containerColor = if (profitPreview.estimatedProfitPaise > 0) Color(0xFF0F172A) else Color(0xFF7F1D1D)
                ),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(18.dp)) {
                    Text(
                        "LIVE CONTRIBUTION MARGIN PREVIEW",
                        color = Color(0xFF94A3B8),
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.Bottom
                    ) {
                        Text(
                            text = String.format("₹%,.2f", profitPreview.estimatedProfitPaise / 100.0),
                            color = if (profitPreview.estimatedProfitPaise > 0) Color(0xFF22C55E) else Color(0xFFFCA5A5),
                            fontSize = 30.sp,
                            fontWeight = FontWeight.Black
                        )
                        Text(
                            text = String.format("%.1f%% Margin", profitPreview.marginPercentage),
                            color = Color.White,
                            fontWeight = FontWeight.Bold,
                            fontSize = 15.sp
                        )
                    }

                    Spacer(modifier = Modifier.height(10.dp))
                    Divider(color = Color(0xFF334155))
                    Spacer(modifier = Modifier.height(10.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("Wholesale COGS: ₹${productCostPaise / 100}", color = Color(0xFFCBD5E1), fontSize = 12.sp)
                        Text("Shipping + Pkg: ₹${(shippingCostPaise + packagingCostPaise) / 100}", color = Color(0xFFCBD5E1), fontSize = 12.sp)
                        Text("Gateway Fee: ₹${profitPreview.paymentFeePaise / 100}", color = Color(0xFFCBD5E1), fontSize = 12.sp)
                    }

                    if (profitPreview.marginPercentage < 15.0 && profitPreview.estimatedProfitPaise > 0) {
                        Spacer(modifier = Modifier.height(10.dp))
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .background(Color(0xFFFEF3C7), RoundedCornerShape(8.dp))
                                .padding(horizontal = 10.dp, vertical = 6.dp)
                        ) {
                            Icon(Icons.Default.Warning, contentDescription = null, tint = Color(0xFFB45309), modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                "Thin Margin Alert: High RTO risk might eliminate your profit.",
                                color = Color(0xFF92400E),
                                fontSize = 11.sp,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))
            Text("Product Information", fontWeight = FontWeight.Bold, fontSize = 16.sp)
            Spacer(modifier = Modifier.height(8.dp))

            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                label = { Text("Product Title") },
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(10.dp))

            OutlinedTextField(
                value = description,
                onValueChange = { description = it },
                label = { Text("Product Description") },
                minLines = 2,
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(10.dp))

            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedTextField(
                    value = sku,
                    onValueChange = { sku = it },
                    label = { Text("SKU Code") },
                    modifier = Modifier.weight(1f)
                )
                OutlinedTextField(
                    value = stockStr,
                    onValueChange = { stockStr = it },
                    label = { Text("Total Stock") },
                    modifier = Modifier.weight(1f)
                )
            }

            Spacer(modifier = Modifier.height(18.dp))
            Text("Pricing & Internal Cost Breakdown", fontWeight = FontWeight.Bold, fontSize = 16.sp)
            Spacer(modifier = Modifier.height(8.dp))

            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedTextField(
                    value = sellingPriceStr,
                    onValueChange = { sellingPriceStr = it },
                    label = { Text("Selling Price (₹)") },
                    prefix = { Text("₹") },
                    modifier = Modifier.weight(1f)
                )
                OutlinedTextField(
                    value = productCostStr,
                    onValueChange = { productCostStr = it },
                    label = { Text("Wholesale COGS (₹)") },
                    prefix = { Text("₹") },
                    modifier = Modifier.weight(1f)
                )
            }

            Spacer(modifier = Modifier.height(10.dp))

            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedTextField(
                    value = packagingCostStr,
                    onValueChange = { packagingCostStr = it },
                    label = { Text("Packaging (₹)") },
                    prefix = { Text("₹") },
                    modifier = Modifier.weight(1f)
                )
                OutlinedTextField(
                    value = shippingCostStr,
                    onValueChange = { shippingCostStr = it },
                    label = { Text("Courier (₹)") },
                    prefix = { Text("₹") },
                    modifier = Modifier.weight(1f)
                )
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Variants Section
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Variants & Inventory", fontWeight = FontWeight.Bold, fontSize = 16.sp)
                TextButton(onClick = {
                    variants.add(
                        ProductVariant(
                            id = "v${variants.size + 1}",
                            name = "Variant ${variants.size + 1}",
                            priceDeltaPaise = 0L,
                            stock = 10
                        )
                    )
                }) {
                    Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Add Variant")
                }
            }

            variants.forEachIndexed { index, variant ->
                Card(
                    colors = CardDefaults.cardColors(containerColor = Color.White),
                    shape = RoundedCornerShape(8.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 4.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .padding(12.dp)
                            .fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(variant.name, fontWeight = FontWeight.Medium, fontSize = 14.sp)
                        Text("Stock: ${variant.stock}", color = Color.Gray, fontSize = 12.sp)
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            Button(
                onClick = {
                    if (name.isBlank() || sellingPricePaise <= 0L) return@Button
                    isSaving = true

                    val product = Product(
                        id = "prod_${System.currentTimeMillis().toString().takeLast(6)}",
                        businessId = businessId,
                        name = name,
                        description = description,
                        sku = sku,
                        currency = "INR",
                        sellingPricePaise = sellingPricePaise,
                        discountPaise = discountPaise,
                        productCostPaise = productCostPaise,
                        packagingCostPaise = packagingCostPaise,
                        shippingCostPaise = shippingCostPaise,
                        stockQuantity = stockStr.toIntOrNull() ?: 0,
                        variants = variants.toList(),
                        images = listOf("https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=800&auto=format&fit=crop"),
                        isActive = true,
                        createdAt = java.time.Instant.now().toString()
                    )

                    coroutineScope.launch {
                        repository.saveProduct(product)
                        isSaving = false
                        onProductSaved(product)
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF0F172A)),
                enabled = !isSaving
            ) {
                if (isSaving) {
                    CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
                } else {
                    Icon(Icons.Default.Check, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Publish Product & Generate Storefront Link", fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}
