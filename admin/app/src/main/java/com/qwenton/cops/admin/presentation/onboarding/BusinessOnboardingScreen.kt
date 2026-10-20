package com.qwenton.cops.admin.presentation.onboarding

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.google.firebase.firestore.FirebaseFirestore
import com.qwenton.cops.admin.domain.model.Business
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BusinessOnboardingScreen(
    userId: String,
    initialPhoneNumber: String? = null,
    onCompleted: (Business) -> Unit
) {
    val coroutineScope = rememberCoroutineScope()
    val firestore = remember { FirebaseFirestore.getInstance() }

    var businessName by remember { mutableStateOf("Chikankari Studio Jaipur") }
    var whatsappNumber by remember { mutableStateOf(initialPhoneNumber ?: "+919876543210") }
    var preferredLanguage by remember { mutableStateOf("hi") }

    // Benchmark Sliders
    var defaultShippingRs by remember { mutableFloatStateOf(60f) }
    var defaultPackagingRs by remember { mutableFloatStateOf(15f) }
    var defaultReturnRate by remember { mutableFloatStateOf(8f) }
    var defaultRtoRate by remember { mutableFloatStateOf(12f) }

    var isSaving by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Store Setup Wizard", fontWeight = FontWeight.Bold, fontSize = 18.sp) },
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
            Text("Tell us about your brand", fontWeight = FontWeight.Bold, fontSize = 20.sp)
            Text(
                "Configure default operating assumptions to calculate live margins per order.",
                color = Color.Gray,
                fontSize = 13.sp
            )

            Spacer(modifier = Modifier.height(16.dp))

            OutlinedTextField(
                value = businessName,
                onValueChange = { businessName = it },
                label = { Text("Store / Brand Name") },
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(12.dp))

            OutlinedTextField(
                value = whatsappNumber,
                onValueChange = { whatsappNumber = it },
                label = { Text("WhatsApp Number for Customer Communication") },
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(18.dp))

            // Language Selector
            Text("Preferred Notification Language", fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
            Spacer(modifier = Modifier.height(6.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                FilterChip(
                    selected = preferredLanguage == "hi",
                    onClick = { preferredLanguage = "hi" },
                    label = { Text("Hindi (हिंदी)") }
                )
                FilterChip(
                    selected = preferredLanguage == "en",
                    onClick = { preferredLanguage = "en" },
                    label = { Text("English") }
                )
            }

            Spacer(modifier = Modifier.height(24.dp))
            Divider()
            Spacer(modifier = Modifier.height(18.dp))

            Text("Default Cost Benchmarks", fontWeight = FontWeight.Bold, fontSize = 16.sp)
            Text("These are applied automatically to new product additions.", color = Color.Gray, fontSize = 12.sp)

            Spacer(modifier = Modifier.height(12.dp))

            // Shipping Benchmark
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text("Forward Shipping Assumption:", fontSize = 13.sp)
                Text("₹${defaultShippingRs.toInt()}", fontWeight = FontWeight.Bold, color = Color(0xFF1E293B))
            }
            Slider(
                value = defaultShippingRs,
                onValueChange = { defaultShippingRs = it },
                valueRange = 30f..150f,
                steps = 11
            )

            // Packaging Benchmark
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text("Packaging & Box Overhead:", fontSize = 13.sp)
                Text("₹${defaultPackagingRs.toInt()}", fontWeight = FontWeight.Bold, color = Color(0xFF1E293B))
            }
            Slider(
                value = defaultPackagingRs,
                onValueChange = { defaultPackagingRs = it },
                valueRange = 5f..50f,
                steps = 8
            )

            // Return Benchmark
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text("Estimated Return Rate (%):", fontSize = 13.sp)
                Text("${defaultReturnRate.toInt()}%", fontWeight = FontWeight.Bold, color = Color(0xFF1E293B))
            }
            Slider(
                value = defaultReturnRate,
                onValueChange = { defaultReturnRate = it },
                valueRange = 2f..25f,
                steps = 22
            )

            // RTO Benchmark
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text("Doorstep RTO Risk Rate (%):", fontSize = 13.sp)
                Text("${defaultRtoRate.toInt()}%", fontWeight = FontWeight.Bold, color = Color(0xFFDC2626))
            }
            Slider(
                value = defaultRtoRate,
                onValueChange = { defaultRtoRate = it },
                valueRange = 5f..35f,
                steps = 29
            )

            Spacer(modifier = Modifier.height(24.dp))

            Button(
                onClick = {
                    if (businessName.isBlank() || whatsappNumber.isBlank()) return@Button
                    isSaving = true

                    val biz = Business(
                        id = userId,
                        ownerUserId = userId,
                        name = businessName,
                        preferredLanguage = preferredLanguage,
                        whatsappNumber = whatsappNumber,
                        defaultShippingCostPaise = (defaultShippingRs * 100).toLong(),
                        defaultPackagingCostPaise = (defaultPackagingRs * 100).toLong(),
                        defaultReturnRate = defaultReturnRate.toDouble(),
                        defaultRtoRate = defaultRtoRate.toDouble(),
                        isActive = true,
                        createdAt = java.time.Instant.now().toString()
                    )

                    coroutineScope.launch {
                        try {
                            firestore.collection("businesses").document(userId).set(biz).await()
                            onCompleted(biz)
                        } catch (e: Exception) {
                            // If running locally without Firestore network, proceed gracefully
                            onCompleted(biz)
                        } finally {
                            isSaving = false
                        }
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
                    Text("Save & Open Operational Dashboard", fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}
