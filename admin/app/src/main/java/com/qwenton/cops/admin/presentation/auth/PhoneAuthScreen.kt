package com.qwenton.cops.admin.presentation.auth

import android.app.Activity
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Lock
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
import com.qwenton.cops.admin.data.auth.AuthRepository
import com.qwenton.cops.admin.data.auth.AuthState
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PhoneAuthScreen(
    authRepository: AuthRepository = remember { AuthRepository() },
    onAuthenticated: (userId: String, phoneNumber: String?) -> Unit
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()

    var phoneNumber by remember { mutableStateOf("9876543210") }
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
        // App Badge
        Surface(
            shape = RoundedCornerShape(12.dp),
            color = Color(0xFF1E293B),
            modifier = Modifier.size(56.dp)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Text("QC", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 20.sp)
            }
        }

        Spacer(modifier = Modifier.height(16.dp))
        Text("Seller Login & Operations", fontSize = 22.sp, fontWeight = FontWeight.Bold)
        Text("Qwenton CommerceOps Engine", color = Color.Gray, fontSize = 13.sp)

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
            // Phone Number Input
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
                            authRepository.sendOtp(activity, phoneNumber).collect { state ->
                                when (state) {
                                    is AuthState.Loading -> isLoading = true
                                    is AuthState.CodeSent -> {
                                        isLoading = false
                                        verificationId = state.verificationId
                                    }
                                    is AuthState.Authenticated -> {
                                        isLoading = false
                                        onAuthenticated(state.userId, state.phoneNumber)
                                    }
                                    is AuthState.Error -> {
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
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF0F172A)),
                enabled = !isLoading
            ) {
                if (isLoading) {
                    CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
                } else {
                    Text("Get Verification Code", fontWeight = FontWeight.Bold)
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Dev Mode One-Tap Shortcut
            OutlinedButton(
                onClick = {
                    phoneNumber = "9876543210"
                    verificationId = "mock_verification_id_jaipur"
                    otpCode = "123456"
                },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(10.dp)
            ) {
                Text("⚡ Quick Test Seller (+91 98765 43210)", fontSize = 12.sp)
            }
        } else {
            // OTP Code Input
            Text(
                "Enter 6-digit OTP sent to +91 $phoneNumber",
                fontSize = 13.sp,
                color = Color.DarkGray
            )
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
                            onAuthenticated(state.userId, state.phoneNumber)
                        }.onFailure { e ->
                            errorMessage = e.localizedMessage ?: "Invalid verification code"
                        }
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                shape = RoundedCornerShape(10.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF0F172A)),
                enabled = !isLoading
            ) {
                if (isLoading) {
                    CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
                } else {
                    Text("Verify & Access Dashboard", fontWeight = FontWeight.Bold)
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            TextButton(onClick = { verificationId = null; otpCode = "" }) {
                Text("Change Mobile Number")
            }
        }
    }
}
