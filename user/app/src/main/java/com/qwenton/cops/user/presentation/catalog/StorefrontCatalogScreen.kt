package com.qwenton.cops.user.presentation.catalog

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.ShoppingCart
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StorefrontCatalogScreen(
    onProductSelectedForCheckout: (product: StoreProduct, variant: StoreProductVariant?, quantity: Int) -> Unit,
    userRepository: FirestoreUserRepository = remember { FirestoreUserRepository() }
) {
    // Seed product fallback for Jaipur social seller
    val defaultProduct = StoreProduct(
        id = "prod_001",
        businessId = "biz_jaipur_01",
        businessName = "Chikankari Studio Jaipur",
        sellerWhatsapp = "919876543210",
        name = "Hand Embroidered Chikankari Kurti - Pastel Pink",
        description = "Pure modal cotton with intricate Lucknow hand embroidery. Breathable, comfortable, and elegant.",
        currency = "INR",
        sellingPricePaise = 99900L,
        discountPaise = 5000L,
        variants = listOf(
            StoreProductVariant("v1", "Size: S", 0L, 10),
            StoreProductVariant("v2", "Size: M", 0L, 20),
            StoreProductVariant("v3", "Size: L", 0L, 15),
            StoreProductVariant("v4", "Size: XL", 5000L, 8)
        ),
        stockQuantity = 45,
        isActive = true
    )

    var productList by remember { mutableStateOf(listOf(defaultProduct)) }
    var selectedProductForModal by remember { mutableStateOf<StoreProduct?>(null) }
    var selectedVariant by remember { mutableStateOf<StoreProductVariant?>(null) }
    var quantity by remember { mutableIntStateOf(1) }

    LaunchedEffect(Unit) {
        userRepository.observePublicCatalog().collect { list ->
            if (list.isNotEmpty()) {
                productList = list
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text("Chikankari Studio Jaipur", fontWeight = FontWeight.Bold, fontSize = 17.sp)
                        Text("Direct Verified Creator Store", color = Color(0xFF16A34A), fontSize = 11.sp, fontWeight = FontWeight.Medium)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.White)
            )
        }
    ) { padding ->
        LazyVerticalGrid(
            columns = GridCells.Fixed(1),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            items(productList) { product ->
                ProductCard(
                    product = product,
                    onBuyClicked = {
                        selectedProductForModal = product
                        selectedVariant = product.variants.firstOrNull()
                    }
                )
            }
        }
    }

    // Variant Selection & Quick Checkout Bottom Sheet
    if (selectedProductForModal != null) {
        val prod = selectedProductForModal!!

        ModalBottomSheet(
            onDismissRequest = { selectedProductForModal = null },
            shape = RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp),
            containerColor = Color.White
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp)
                    .padding(bottom = 32.dp)
            ) {
                Text(prod.name, fontWeight = FontWeight.Bold, fontSize = 17.sp)
                Spacer(modifier = Modifier.height(4.dp))
                Text(prod.description, color = Color.Gray, fontSize = 12.sp)

                Spacer(modifier = Modifier.height(14.dp))
                Text("Select Variant / Size:", fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
                Spacer(modifier = Modifier.height(8.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    prod.variants.forEach { v ->
                        FilterChip(
                            selected = selectedVariant?.id == v.id,
                            onClick = { selectedVariant = v },
                            label = { Text(v.name, fontSize = 12.sp) }
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        val unitPrice = prod.effectivePricePaise + (selectedVariant?.priceDeltaPaise ?: 0L)
                        Text(String.format("₹%,.2f", (unitPrice * quantity) / 100.0), fontSize = 24.sp, fontWeight = FontWeight.Black, color = Color(0xFF0F172A))
                        Text("Inclusive of all taxes & free shipping", color = Color(0xFF16A34A), fontSize = 11.sp, fontWeight = FontWeight.Medium)
                    }

                    // Quantity incrementer
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        OutlinedButton(
                            onClick = { if (quantity > 1) quantity-- },
                            contentPadding = PaddingValues(horizontal = 12.dp)
                        ) {
                            Text("-", fontSize = 16.sp, fontWeight = FontWeight.Bold)
                        }
                        Text("$quantity", fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = 12.dp))
                        OutlinedButton(
                            onClick = { quantity++ },
                            contentPadding = PaddingValues(horizontal = 12.dp)
                        ) {
                            Text("+", fontSize = 16.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))

                Button(
                    onClick = {
                        val p = selectedProductForModal!!
                        val v = selectedVariant
                        val q = quantity
                        selectedProductForModal = null
                        onProductSelectedForCheckout(p, v, q)
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1877F2))
                ) {
                    Icon(Icons.Default.ShoppingCart, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Proceed to Delivery Address", fontWeight = FontWeight.Bold, fontSize = 15.sp)
                }
            }
        }
    }
}

@Composable
fun ProductCard(
    product: StoreProduct,
    onBuyClicked: () -> Unit
) {
    Card(
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Surface(
                    shape = RoundedCornerShape(6.dp),
                    color = Color(0xFFDC2626)
                ) {
                    Text(
                        text = "₹${product.discountPaise / 100} OFF",
                        color = Color.White,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                    )
                }

                Text(
                    text = "${product.stockQuantity} in stock",
                    color = Color(0xFF16A34A),
                    fontSize = 12.sp,
                    fontWeight = FontWeight.SemiBold
                )
            }

            Spacer(modifier = Modifier.height(10.dp))
            Text(product.name, fontWeight = FontWeight.Bold, fontSize = 16.sp, color = Color(0xFF0F172A))
            Spacer(modifier = Modifier.height(4.dp))
            Text(product.description, color = Color.Gray, fontSize = 12.sp, lineHeight = 16.sp)

            Spacer(modifier = Modifier.height(14.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.Bottom) {
                    Text(
                        text = String.format("₹%,.2f", product.effectivePriceRupees),
                        fontSize = 22.sp,
                        fontWeight = FontWeight.Black,
                        color = Color(0xFF0F172A)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "₹${product.sellingPricePaise / 100}",
                        fontSize = 14.sp,
                        color = Color.Gray,
                        style = androidx.compose.ui.text.TextStyle(
                            textDecoration = androidx.compose.ui.text.style.TextDecoration.LineThrough
                        )
                    )
                }

                Button(
                    onClick = onBuyClicked,
                    shape = RoundedCornerShape(10.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1877F2))
                ) {
                    Text("Select & Order", fontWeight = FontWeight.Bold, fontSize = 13.sp)
                }
            }
        }
    }
}
