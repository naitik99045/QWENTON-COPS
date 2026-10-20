package com.qwenton.cops.user

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import com.qwenton.cops.user.domain.model.StoreProduct
import com.qwenton.cops.user.domain.model.StoreProductVariant
import com.qwenton.cops.user.presentation.auth.CustomerAuthScreen
import com.qwenton.cops.user.presentation.catalog.StorefrontCatalogScreen
import com.qwenton.cops.user.presentation.checkout.CheckoutScreen
import com.qwenton.cops.user.presentation.payment.PaymentProcessingScreen
import com.qwenton.cops.user.presentation.tracking.OrderTrackingScreen

enum class CustomerScreenState {
    AUTH,
    CATALOG,
    CHECKOUT,
    PAYMENT_PROCESSING,
    TRACKING
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
                    CustomerAppRoot()
                }
            }
        }
    }
}

@Composable
fun CustomerAppRoot() {
    var screenState by remember { mutableStateOf(CustomerScreenState.CATALOG) }
    var currentCustomerId by remember { mutableStateOf("cust_guest_001") }

    // Checkout Selection State
    var selectedProduct by remember { mutableStateOf<StoreProduct?>(null) }
    var selectedVariant by remember { mutableStateOf<StoreProductVariant?>(null) }
    var selectedQuantity by remember { mutableIntStateOf(1) }

    // Active Order & Payment State
    var activeOrderId by remember { mutableStateOf("") }
    var activeOrderNumber by remember { mutableStateOf("") }
    var activeTotalPaise by remember { mutableStateOf(0L) }
    var activeCustomerName by remember { mutableStateOf("") }
    var activeCustomerPhone by remember { mutableStateOf("") }

    when (screenState) {
        CustomerScreenState.AUTH -> {
            CustomerAuthScreen(
                onAuthenticated = { uid, isGuest ->
                    currentCustomerId = uid
                    screenState = CustomerScreenState.CATALOG
                }
            )
        }

        CustomerScreenState.CATALOG -> {
            StorefrontCatalogScreen(
                onProductSelectedForCheckout = { product, variant, quantity ->
                    selectedProduct = product
                    selectedVariant = variant
                    selectedQuantity = quantity
                    screenState = CustomerScreenState.CHECKOUT
                }
            )
        }

        CustomerScreenState.CHECKOUT -> {
            selectedProduct?.let { prod ->
                CheckoutScreen(
                    product = prod,
                    variant = selectedVariant,
                    quantity = selectedQuantity,
                    customerId = currentCustomerId,
                    onBack = { screenState = CustomerScreenState.CATALOG },
                    onProceedToPayment = { orderId, orderNumber, totalPaise, name, phone, paymentMethod ->
                        activeOrderId = orderId
                        activeOrderNumber = orderNumber
                        activeTotalPaise = totalPaise
                        activeCustomerName = name
                        activeCustomerPhone = phone

                        if (paymentMethod == "famgateway") {
                            screenState = CustomerScreenState.PAYMENT_PROCESSING
                        } else {
                            // COD Confirmed directly
                            screenState = CustomerScreenState.TRACKING
                        }
                    }
                )
            }
        }

        CustomerScreenState.PAYMENT_PROCESSING -> {
            PaymentProcessingScreen(
                orderId = activeOrderId,
                orderNumber = activeOrderNumber,
                totalPaise = activeTotalPaise,
                customerName = activeCustomerName,
                customerPhone = activeCustomerPhone,
                businessId = selectedProduct?.businessId ?: "biz_jaipur_01",
                onPaymentSuccess = { orderId, orderNumber ->
                    activeOrderId = orderId
                    activeOrderNumber = orderNumber
                    screenState = CustomerScreenState.TRACKING
                }
            )
        }

        CustomerScreenState.TRACKING -> {
            OrderTrackingScreen(
                orderId = activeOrderId,
                orderNumber = activeOrderNumber,
                sellerWhatsapp = selectedProduct?.sellerWhatsapp ?: "919876543210",
                onBackToStore = {
                    screenState = CustomerScreenState.CATALOG
                }
            )
        }
    }
}
