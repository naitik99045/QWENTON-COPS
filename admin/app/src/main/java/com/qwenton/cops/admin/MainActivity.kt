package com.qwenton.cops.admin

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.qwenton.cops.admin.domain.model.Business
import com.qwenton.cops.admin.domain.model.Order
import com.qwenton.cops.admin.domain.model.Product
import com.qwenton.cops.admin.presentation.auth.PhoneAuthScreen
import com.qwenton.cops.admin.presentation.onboarding.BusinessOnboardingScreen
import com.qwenton.cops.admin.presentation.orders.OrderDetailScreen
import com.qwenton.cops.admin.presentation.products.AddEditProductScreen
import com.qwenton.cops.admin.presentation.settings.SettingsScreen

enum class AdminScreenState {
    AUTH,
    ONBOARDING,
    MAIN_APP,
    ADD_PRODUCT,
    ORDER_DETAIL
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = Color(0xFFF8FAFC)
                ) {
                    AdminAppRoot()
                }
            }
        }
    }
}

@Composable
fun AdminAppRoot() {
    var screenState by remember { mutableStateOf(AdminScreenState.MAIN_APP) }
    var currentUserId by remember { mutableStateOf("admin_jaipur_demo_uid") }
    var selectedOrderForDetail by remember { mutableStateOf<Order?>(null) }

    var currentBusiness by remember {
        mutableStateOf(
            Business(
                id = "biz_jaipur_01",
                ownerUserId = "admin_jaipur_demo_uid",
                name = "Chikankari Studio Jaipur",
                preferredLanguage = "hi",
                whatsappNumber = "+919876543210",
                defaultShippingCostPaise = 6000L,
                defaultPackagingCostPaise = 1500L,
                defaultReturnRate = 8.0,
                defaultRtoRate = 12.0
            )
        )
    }

    val orders = remember {
        mutableStateListOf(
            Order(
                id = "ord_001",
                orderNumber = "QC-20261020-001",
                businessId = "biz_jaipur_01",
                customerName = "Pooja Sharma",
                customerPhone = "9811223344",
                deliveryAddress = "Flat 402, Lotus Heights, Malviya Nagar",
                city = "Jaipur",
                pincode = "302017",
                paymentMethod = "famgateway",
                paymentStatus = "paid",
                fulfilmentStatus = "to_pack",
                netSalesPaise = 94900L,
                subtotalPaise = 94900L,
                productCostPaise = 42000L,
                packagingCostPaise = 1500L,
                shippingPaise = 6000L,
                paymentFeePaise = 1898L,
                estimatedProfitPaise = 39930L,
                famgatewayTxnId = "FG_TXN_8849204820",
                famgatewayUtr = "428901234567",
                createdAt = "2026-10-20T11:30:00Z"
            ),
            Order(
                id = "ord_002",
                orderNumber = "QC-20261020-002",
                businessId = "biz_jaipur_01",
                customerName = "Ananya Verma",
                customerPhone = "9876500112",
                deliveryAddress = "12/A, Civil Lines",
                city = "Jaipur",
                pincode = "302006",
                paymentMethod = "famgateway",
                paymentStatus = "paid",
                fulfilmentStatus = "shipped",
                netSalesPaise = 149900L,
                subtotalPaise = 149900L,
                productCostPaise = 65000L,
                packagingCostPaise = 1500L,
                shippingPaise = 6000L,
                paymentFeePaise = 2998L,
                estimatedProfitPaise = 62000L,
                courierName = "BlueDart",
                trackingNumber = "BD893041920",
                createdAt = "2026-10-20T10:15:00Z"
            )
        )
    }

    val products = remember {
        mutableStateListOf(
            Product(
                id = "prod_001",
                businessId = "biz_jaipur_01",
                name = "Hand Embroidered Chikankari Kurti - Pastel Pink",
                description = "Pure modal cotton with Lucknow hand embroidery.",
                sku = "CHK-KURTI-PNK",
                currency = "INR",
                sellingPricePaise = 94900L,
                productCostPaise = 42000L,
                packagingCostPaise = 1500L,
                shippingCostPaise = 6000L,
                stockQuantity = 45,
                isActive = true
            )
        )
    }

    when (screenState) {
        AdminScreenState.AUTH -> {
            PhoneAuthScreen(
                onAuthenticated = { uid, phone ->
                    currentUserId = uid
                    screenState = AdminScreenState.ONBOARDING
                }
            )
        }

        AdminScreenState.ONBOARDING -> {
            BusinessOnboardingScreen(
                userId = currentUserId,
                onCompleted = { biz ->
                    currentBusiness = biz
                    screenState = AdminScreenState.MAIN_APP
                }
            )
        }

        AdminScreenState.ADD_PRODUCT -> {
            AddEditProductScreen(
                businessId = currentBusiness.id,
                onBack = { screenState = AdminScreenState.MAIN_APP },
                onProductSaved = { prod ->
                    products.add(0, prod)
                    screenState = AdminScreenState.MAIN_APP
                }
            )
        }

        AdminScreenState.ORDER_DETAIL -> {
            selectedOrderForDetail?.let { ord ->
                OrderDetailScreen(
                    order = ord,
                    onBack = {
                        selectedOrderForDetail = null
                        screenState = AdminScreenState.MAIN_APP
                    }
                )
            }
        }

        AdminScreenState.MAIN_APP -> {
            AdminMainScaffold(
                business = currentBusiness,
                orders = orders,
                products = products,
                onOrderClicked = { ord ->
                    selectedOrderForDetail = ord
                    screenState = AdminScreenState.ORDER_DETAIL
                },
                onAddProductClicked = {
                    screenState = AdminScreenState.ADD_PRODUCT
                },
                onSignOut = {
                    screenState = AdminScreenState.AUTH
                }
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdminMainScaffold(
    business: Business,
    orders: List<Order>,
    products: List<Product>,
    onOrderClicked: (Order) -> Unit,
    onAddProductClicked: () -> Unit,
    onSignOut: () -> Unit
) {
    var selectedTab by remember { mutableStateOf(0) }
    val tabs = listOf("Dashboard", "Orders", "Catalogue", "Settings")

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(business.name, fontWeight = FontWeight.Bold, fontSize = 17.sp)
                        Text("Vercel Backend: qwen.qwenton.shop", color = Color(0xFF16A34A), fontSize = 11.sp, fontWeight = FontWeight.Medium)
                    }
                },
                actions = {
                    if (selectedTab == 2) {
                        IconButton(onClick = onAddProductClicked) {
                            Icon(Icons.Default.Add, contentDescription = "Add Product", tint = Color(0xFF0F172A))
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.White)
            )
        },
        bottomBar = {
            NavigationBar(containerColor = Color.White) {
                tabs.forEachIndexed { index, title ->
                    NavigationBarItem(
                        selected = selectedTab == index,
                        onClick = { selectedTab = index },
                        icon = {
                            when (index) {
                                0 -> Icon(Icons.Default.Home, contentDescription = title)
                                1 -> Icon(Icons.Default.ShoppingCart, contentDescription = title)
                                2 -> Icon(Icons.Default.List, contentDescription = title)
                                else -> Icon(Icons.Default.Settings, contentDescription = title)
                            }
                        },
                        label = { Text(title, fontSize = 11.sp) }
                    )
                }
            }
        }
    ) { padding ->
        Box(modifier = Modifier.padding(padding)) {
            when (selectedTab) {
                0 -> MainDashboardView(orders, onOrderClicked)
                1 -> MainOrderFeedView(orders, onOrderClicked)
                2 -> MainCatalogueView(products, onAddProductClicked)
                3 -> SettingsScreen(business, orders, onSignOut)
            }
        }
    }
}

@Composable
fun MainDashboardView(orders: List<Order>, onOrderClicked: (Order) -> Unit) {
    val totalProfitPaise = orders.sumOf { it.estimatedProfitPaise }
    val totalRevenuePaise = orders.sumOf { it.netSalesPaise }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Card(
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = Color(0xFF0F172A)),
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(modifier = Modifier.padding(20.dp)) {
                Text("ESTIMATED CONTRIBUTION PROFIT", color = Color(0xFF94A3B8), fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    String.format("₹%,.2f", totalProfitPaise / 100.0),
                    color = Color(0xFF22C55E),
                    fontSize = 32.sp,
                    fontWeight = FontWeight.Black
                )
                Spacer(modifier = Modifier.height(14.dp))
                Divider(color = Color(0xFF334155))
                Spacer(modifier = Modifier.height(14.dp))

                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Column {
                        Text("Gross Sales", color = Color(0xFF94A3B8), fontSize = 11.sp)
                        Text(String.format("₹%,.2f", totalRevenuePaise / 100.0), color = Color.White, fontWeight = FontWeight.Bold, fontSize = 15.sp)
                    }
                    Column {
                        Text("FamGateway Webhook", color = Color(0xFF94A3B8), fontSize = 11.sp)
                        Text("Active (Live)", color = Color(0xFF38BDF8), fontWeight = FontWeight.Bold, fontSize = 15.sp)
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(20.dp))
        Text("Active Orders Feed", fontWeight = FontWeight.Bold, fontSize = 16.sp)
        Spacer(modifier = Modifier.height(10.dp))

        LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            items(orders) { order ->
                OrderFeedItem(order, onClick = { onOrderClicked(order) })
            }
        }
    }
}

@Composable
fun MainOrderFeedView(orders: List<Order>, onOrderClicked: (Order) -> Unit) {
    var selectedFilter by remember { mutableStateOf("all") }
    val filters = listOf("all", "to_pack", "shipped", "delivered")

    val filteredOrders = remember(selectedFilter, orders) {
        if (selectedFilter == "all") orders else orders.filter { it.fulfilmentStatus == selectedFilter }
    }

    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            filters.forEach { f ->
                FilterChip(
                    selected = selectedFilter == f,
                    onClick = { selectedFilter = f },
                    label = { Text(f.replace("_", " ").uppercase(), fontSize = 11.sp) }
                )
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            items(filteredOrders) { order ->
                OrderFeedItem(order, onClick = { onOrderClicked(order) })
            }
        }
    }
}

@Composable
fun OrderFeedItem(order: Order, onClick: () -> Unit) {
    Card(
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(order.orderNumber, fontWeight = FontWeight.Bold, fontSize = 15.sp)
                AssistChip(
                    onClick = onClick,
                    label = { Text(order.fulfilmentStatus.uppercase(), fontSize = 10.sp, fontWeight = FontWeight.Bold) }
                )
            }
            Spacer(modifier = Modifier.height(4.dp))
            Text(order.customerName, fontWeight = FontWeight.Medium, fontSize = 14.sp)
            Text("+91 ${order.customerPhone}", color = Color.Gray, fontSize = 12.sp)

            if (order.famgatewayUtr != null) {
                Spacer(modifier = Modifier.height(4.dp))
                Text("FamGateway UTR: ${order.famgatewayUtr}", color = Color(0xFF16A34A), fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
            }

            Spacer(modifier = Modifier.height(8.dp))
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text(
                    text = "Profit: ${order.formatRupees(order.estimatedProfitPaise)}",
                    color = Color(0xFF15803D),
                    fontWeight = FontWeight.Bold,
                    fontSize = 13.sp
                )
                Text(
                    text = "Total: ${order.formatRupees(order.netSalesPaise)}",
                    fontWeight = FontWeight.Bold,
                    fontSize = 13.sp
                )
            }
        }
    }
}

@Composable
fun MainCatalogueView(products: List<Product>, onAddProductClicked: () -> Unit) {
    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text("Product Catalogue", fontWeight = FontWeight.Bold, fontSize = 18.sp)
            Button(
                onClick = onAddProductClicked,
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF0F172A))
            ) {
                Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(4.dp))
                Text("New Product", fontSize = 13.sp)
            }
        }

        Spacer(modifier = Modifier.height(14.dp))

        LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            items(products) { p ->
                Card(
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(containerColor = Color.White),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Text(p.name, fontWeight = FontWeight.Bold, fontSize = 15.sp)
                        Text("SKU: ${p.sku} | Stock: ${p.stockQuantity}", color = Color.Gray, fontSize = 12.sp)
                        Spacer(modifier = Modifier.height(8.dp))
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text("Price: ₹${p.sellingPricePaise / 100}", fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
                            Text("COGS: ₹${p.productCostPaise / 100}", color = Color.Gray, fontSize = 13.sp)
                            val margin = if (p.sellingPricePaise > 0) {
                                ((p.sellingPricePaise - p.productCostPaise - p.packagingCostPaise - p.shippingCostPaise).toDouble() / p.sellingPricePaise.toDouble()) * 100.0
                            } else 0.0
                            Text(String.format("Margin: %.1f%%", margin), color = Color(0xFF16A34A), fontWeight = FontWeight.Bold, fontSize = 13.sp)
                        }
                    }
                }
            }
        }
    }
}
