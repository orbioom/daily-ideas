package com.orbioom.frond.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.orbioom.frond.ui.theme.OrbInk
import com.orbioom.frond.ui.theme.OrbText
import com.orbioom.frond.ui.theme.OrbText3

@Composable
fun AddPlantDialog(
    onDismiss: () -> Unit,
    onAdd: (name: String, species: String, intervalDays: Int) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var species by remember { mutableStateOf("") }
    var interval by remember { mutableStateOf("7") }

    val valid = name.isNotBlank() && (interval.toIntOrNull() ?: 0) >= 1

    AlertDialog(
        onDismissRequest = onDismiss,
        shape = RoundedCornerShape(22.dp),
        title = { Text("New plant", color = OrbText) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedTextField(
                    value = name, onValueChange = { name = it },
                    label = { Text("Name") }, singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = species, onValueChange = { species = it },
                    label = { Text("Species (optional)") }, singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = interval,
                    onValueChange = { s -> interval = s.filter { it.isDigit() }.take(3) },
                    label = { Text("Water every (days)") }, singleLine = true,
                    keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(
                        keyboardType = KeyboardType.Number),
                    modifier = Modifier.fillMaxWidth()
                )
                Text("Stored only on this device.", color = OrbText3,
                    style = MaterialTheme.typography.labelSmall)
            }
        },
        confirmButton = {
            TextButton(
                onClick = { onAdd(name, species, interval.toIntOrNull() ?: 7) },
                enabled = valid
            ) { Text("Add", color = if (valid) OrbInk else OrbText3) }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel", color = OrbText3) }
        }
    )
}
