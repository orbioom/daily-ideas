package com.orbioom.meeple.ui.screens

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.text.font.FontWeight
import com.orbioom.meeple.ui.theme.LocalBrand

/** A consistent destructive confirmation dialog reused across detail screens and settings. */
@Composable
fun ConfirmDialog(
    title: String,
    body: String,
    confirmLabel: String,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = MaterialTheme.colorScheme.surface,
        title = { Text(title, fontWeight = FontWeight.Bold) },
        text = { Text(body, color = LocalBrand.current.textSecondary) },
        confirmButton = {
            TextButton(onClick = onConfirm) {
                Text(confirmLabel, color = MaterialTheme.colorScheme.error, fontWeight = FontWeight.SemiBold)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        }
    )
}

/** Filter raw text to a single-dot decimal string (digits + one dot). */
fun sanitizeDecimal(raw: String): String {
    val filtered = raw.filter { it.isDigit() || it == '.' || it == '-' }
    // Allow a single leading minus only.
    val negative = filtered.startsWith("-")
    val body = filtered.replace("-", "")
    val firstDot = body.indexOf('.')
    val cleaned = if (firstDot < 0) body
    else body.substring(0, firstDot + 1) + body.substring(firstDot + 1).replace(".", "")
    return if (negative) "-$cleaned" else cleaned
}

/** Filter raw text to digits only (for integer fields like player counts and durations). */
fun sanitizeInt(raw: String): String = raw.filter { it.isDigit() }

/** Trim trailing zeros for editing: 50.0 -> "50". */
fun trimNumber(value: Double): String {
    val s = value.toString()
    return if (s.endsWith(".0")) s.dropLast(2) else s
}
