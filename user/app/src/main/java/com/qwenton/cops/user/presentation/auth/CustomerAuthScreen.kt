package com.qwenton.cops.user.presentation.auth

import android.app.Activity
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.qwenton.cops.user.data.auth.CustomerAuthRepository
import com.qwenton.cops.user.data.auth.CustomerAuthState
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CustomerAuthScreen(
    authRepository: CustomerAuthRepository = remember { CustomerAuthRepository() },
    onAuthenticated: (userId: String, isGuest: Boolean) -> Unit
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()

    var phoneNumber by remember { mutableStateOf("9811223344") }
    var otpCode by remember { mutableStateOf("") }
    var verificationId by remember { mutableStateOf<String?>(null) }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFF8FAFC))
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Surface(
            shape = RoundedCornerShape(12.dp),
            color = Color(0xFF1877F2),
            modifier = Modifier.size(56.dp)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Text("QC", color = Color.White, fontWeight = FontWeight.Black, fontSize = 20.sp)
            }
        }

        Spacer(modifier = Modifier.height(16.dp))
        Text("Welcome to Direct Storefront", fontSize = 22.sp, fontWeight = FontWeight.Bold)
        Text("Verified Creator Direct Commerce", color = Color.Gray, fontSize = 13.sp)

        Spacer(modifier = Modifier.height(24.dp))

        if (errorMessage != null) {
            Card(
                colors = CardDefaults.cardColors(containerColor = Color(0xFFFEE2E2)),
                shape = RoundedCornerShape(8.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = errorMessage ?: "",
                    color = Color(0xFF991B1B),
                    fontSize = 13.sp,
                    modifier = Modifier.padding(12.dp)
                )
            }
            Spacer(modifier = Modifier.height(16.dp))
        }

        if (verificationId == null) {
            OutlinedTextField(
                value = phoneNumber,
                onValueChange = { phoneNumber = it },
                label = { Text("Mobile Number") },
                prefix = { Text("+91 ", fontWeight = FontWeight.Bold) },
                leadingIcon = { Icon(Icons.Default.Phone, contentDescription = null) },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(16.dp))

            Button(
                onClick = {
                    if (phoneNumber.length < 10) {
                        errorMessage = "Please enter a valid 10-digit mobile number"
                        return@Button
                    }
                    errorMessage = null
                    isLoading = true

                    val activity = context as? Activity
                    if (activity != null) {
                        coroutineScope.launch {
                            authRepository.sendPhoneOtp(activity, phoneNumber).collect { state ->
                                when (state) {
                                    is CustomerAuthState.Loading -> isLoading = true
                                    is CustomerAuthState.CodeSent -> {
                                        isLoading = false
                                        verificationId = state.verificationId
                                    }
                                    is CustomerAuthState.Authenticated -> {
                                        isLoading = false
                                        onAuthenticated(state.userId, state.isGuest)
                                    }
                                    is CustomerAuthState.Error -> {
                                        isLoading = false
                                        errorMessage = state.message
                                    }
                                    else -> {}
                                }
                            }
                        }
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                shape = RoundedCornerShape(10.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1877F2)),
                enabled = !isLoading
            ) {
                if (isLoading) {
                    CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
                } else {
                    Text("Continue with Mobile OTP", fontWeight = FontWeight.Bold)
                }
            }

            Spacer(modifier = Modifier.height(16.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Divider(modifier = Modifier.weight(1f))
                Text("  OR  ", color = Color.Gray, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                Divider(modifier = Modifier.weight(1f))
            }
            Spacer(modifier = Modifier.height(16.dp))

            // 1-Tap Guest Checkout
            OutlinedButton(
                onClick = {
                    coroutineScope.launch {
                        isLoading = true
                        val result = authRepository.signInAsGuest()
                        isLoading = false
                        result.onSuccess { sess ->
                            onAuthenticated(sess.userId, true)
                        }
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                shape = RoundedCornerShape(10.dp)
            ) {
                Icon(Icons.Default.Person, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(modifier = Modifier.width(8.dp))
                Text("1-Tap Quick Guest Checkout", fontWeight = FontWeight.SemiBold)
            }
        } else {
            // OTP verification
            Text("Enter 6-digit OTP sent to +91 $phoneNumber", fontSize = 13.sp, color = Color.DarkGray)
            Spacer(modifier = Modifier.height(12.dp))

            OutlinedTextField(
                value = otpCode,
                onValueChange = { if (it.length <= 6) otpCode = it },
                label = { Text("6-Digit PIN") },
                leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null) },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(16.dp))

            Button(
                onClick = {
                    if (otpCode.length != 6) {
                        errorMessage = "Please enter the full 6-digit PIN"
                        return@Button
                    }
                    errorMessage = null
                    isLoading = true

                    coroutineScope.launch {
                        val result = authRepository.verifyOtp(verificationId!!, otpCode)
                        isLoading = false
                        result.onSuccess { state ->
                            onAuthenticated(state.userId, state.isGuest)
                        }.onFailure { e ->
                            errorMessage = e.localizedMessage ?: "Invalid OTP"
                        }
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                shape = RoundedCornerShape(10.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1877F2)),
                enabled = !isLoading
            ) {
                if (isLoading) {
                    CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
                } else {
                    Text("Verify & Start Shopping", fontWeight = FontWeight.Bold)
                }
            }

            Spacer(modifier = Modifier.height(12.dp))
            TextButton(onClick = { verificationId = null; otpCode = "" }) {
                Text("Change Mobile Number")
            }
        }
    }
}
