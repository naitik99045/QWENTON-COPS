package com.qwenton.cops.admin.presentation.whatsapp

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.Toast
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.qwenton.cops.admin.domain.model.Order
import com.qwenton.cops.admin.domain.whatsapp.MessageTemplate
import java.net.URLEncoder

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WhatsAppActionSheet(
    context: Context,
    order: Order,
    storeName: String = "Chikankari Studio Jaipur",
    onDismiss: () -> Unit
) {
    val templates = remember { MessageTemplate.defaultTemplates }
    var selectedTemplate by remember { mutableStateOf(templates.first()) }
    var editableMessage by remember(selectedTemplate, order) {
        mutableStateOf(selectedTemplate.render(order, storeName))
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        shape = RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp),
        containerColor = Color.White
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .padding(bottom = 32.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("WhatsApp Action Center", fontWeight = FontWeight.Bold, fontSize = 18.sp)
                AssistChip(
                    onClick = {},
                    label = { Text("Direct Link", fontSize = 11.sp, color = Color(0xFF16A34A)) }
                )
            }

            Spacer(modifier = Modifier.height(14.dp))
            Text("Select Communication Template:", fontSize = 13.sp, color = Color.Gray)
            Spacer(modifier = Modifier.height(6.dp))

            // Template Selector Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                templates.forEach { tmpl ->
                    FilterChip(
                        selected = selectedTemplate.id == tmpl.id,
                        onClick = {
                            selectedTemplate = tmpl
                            editableMessage = tmpl.render(order, storeName)
                        },
                        label = { Text(tmpl.title, fontSize = 11.sp) }
                    )
                }
            }

            Spacer(modifier = Modifier.height(14.dp))
            Text("Message Preview (Editable):", fontSize = 13.sp, color = Color.Gray)
            Spacer(modifier = Modifier.height(6.dp))

            OutlinedTextField(
                value = editableMessage,
                onValueChange = { editableMessage = it },
                minLines = 5,
                maxLines = 8,
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(18.dp))

            Button(
                onClick = {
                    val phoneClean = order.customerPhone.replace("+", "").replace(" ", "").replace("-", "")
                    val targetPhone = if (phoneClean.startsWith("91")) phoneClean else "91$phoneClean"
                    val encodedText = URLEncoder.encode(editableMessage, "UTF-8")
                    val whatsappUrl = "https://wa.me/$targetPhone?text=$encodedText"

                    try {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(whatsappUrl))
                        context.startActivity(intent)
                        onDismiss()
                    } catch (e: Exception) {
                        Toast.makeText(context, "WhatsApp not installed on this device", Toast.LENGTH_SHORT).show()
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF25D366))
            ) {
                Icon(Icons.Default.Send, contentDescription = null, tint = Color.White)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Open in WhatsApp (+91 ${order.customerPhone})", fontWeight = FontWeight.Bold, color = Color.White)
            }
        }
    }
}
