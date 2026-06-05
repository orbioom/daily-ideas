package com.orbioom.transit.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.orbioom.transit.domain.FillUp
import com.orbioom.transit.domain.Format
import com.orbioom.transit.domain.UnitSystem
import com.orbioom.transit.ui.components.GlassCard
import com.orbioom.transit.ui.components.InkButton
import com.orbioom.transit.ui.components.MistBackground
import com.orbioom.transit.ui.theme.LocalBrand
import com.orbioom.transit.viewmodel.TransitViewModel
import java.util.Calendar
import java.util.UUID

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddEditFillScreen(
    vehicleId: String,
    fillId: String?,
    viewModel: TransitViewModel,
    onDone: () -> Unit,
    onCancel: () -> Unit
) {
    val brand = LocalBrand.current
    val vehicle = remember(vehicleId) { viewModel.vehicle(vehicleId) }
    val existing = remember(fillId) { fillId?.let { viewModel.fill(it) } }
    val isEditing = existing != null
    val system = vehicle?.unitSystem ?: UnitSystem.METRIC

    // The previous odometer for this vehicle (highest reading before this fill) — guidance.
    val priorOdometer = remember(vehicleId, fillId) {
        viewModel.fillsFor(vehicleId)
            .filter { it.id != fillId }
            .maxByOrNull { it.odometer }
            ?.odometer
    }

    var dateMillis by rememberSaveable {
        mutableStateOf(existing?.date ?: System.currentTimeMillis())
    }
    var odometer by rememberSaveable {
        mutableStateOf(existing?.odometer?.let { trimNumber(it) } ?: "")
    }
    var volume by rememberSaveable {
        mutableStateOf(existing?.volume?.let { trimNumber(it) } ?: "")
    }
    var price by rememberSaveable {
        mutableStateOf(existing?.pricePerUnit?.let { trimNumber(it) } ?: "")
    }
    var total by rememberSaveable {
        mutableStateOf(existing?.totalCost?.let { trimNumber(it) } ?: "")
    }
    // Which of price/total the user last edited, so we auto-compute the other.
    var lastEdited by rememberSaveable { mutableStateOf("price") }
    var isFull by rememberSaveable { mutableStateOf(existing?.isFullTank ?: true) }
    var missedPrev by rememberSaveable { mutableStateOf(existing?.isMissedPrevious ?: false) }
    var station by rememberSaveable { mutableStateOf(existing?.station ?: "") }
    var notes by rememberSaveable { mutableStateOf(existing?.notes ?: "") }
    var attemptedSave by rememberSaveable { mutableStateOf(false) }

    // Auto-compute the dependent money field.
    fun recompute() {
        val v = volume.toDoubleOrNull()
        if (v == null || v <= 0.0) return
        if (lastEdited == "price") {
            val p = price.toDoubleOrNull()
            if (p != null) total = Format.number(v * p, 2)
        } else {
            val t = total.toDoubleOrNull()
            if (t != null && v > 0) price = Format.number(t / v, 3)
        }
    }

    val odoValue = odometer.toDoubleOrNull()
    val volValue = volume.toDoubleOrNull()
    val priceValue = price.toDoubleOrNull()
    val totalValue = total.toDoubleOrNull()

    val odoError = odoValue == null || odoValue < 0.0
    val odoRegresses = odoValue != null && priorOdometer != null && odoValue <= priorOdometer
    val volError = volValue == null || volValue <= 0.0
    val priceError = price.isNotBlank() && (priceValue == null || priceValue < 0.0)
    val totalError = total.isNotBlank() && (totalValue == null || totalValue < 0.0)
    val moneyMissing = priceValue == null && totalValue == null

    val canSave = vehicle != null && !odoError && !volError && !priceError &&
        !totalError && !moneyMissing

    fun save() {
        attemptedSave = true
        if (!canSave || vehicle == null) return
        val v = volValue ?: return
        val resolvedTotal = totalValue ?: (priceValue?.let { it * v }) ?: 0.0
        val resolvedPrice = priceValue ?: (if (v > 0) resolvedTotal / v else 0.0)
        val fill = FillUp(
            id = existing?.id ?: "fill-${UUID.randomUUID()}",
            vehicleId = vehicle.id,
            date = dateMillis,
            odometer = odoValue ?: 0.0,
            volume = v,
            pricePerUnit = resolvedPrice,
            totalCost = resolvedTotal,
            isFullTank = isFull,
            isMissedPrevious = missedPrev,
            station = station.trim(),
            notes = notes.trim()
        )
        viewModel.saveFill(fill)
        onDone()
    }

    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            TopAppBar(
                title = {
                    Text(if (isEditing) "Edit fill-up" else "New fill-up", fontWeight = FontWeight.Bold)
                },
                navigationIcon = {
                    IconButton(onClick = onCancel) {
                        Icon(Icons.Filled.Close, contentDescription = "Cancel")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent,
                    titleContentColor = MaterialTheme.colorScheme.onBackground
                )
            )
        }
    ) { padding ->
        MistBackground {
            if (vehicle == null) {
                Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            "That vehicle is no longer available.",
                            style = MaterialTheme.typography.titleMedium,
                            color = MaterialTheme.colorScheme.onBackground
                        )
                        Spacer(Modifier.height(12.dp))
                        InkButton(text = "Go back", onClick = onCancel)
                    }
                }
                return@MistBackground
            }

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                Spacer(Modifier.height(2.dp))

                Text(
                    "Logging to ${vehicle.name} · ${system.title}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = brand.textSecondary
                )

                DateField(dateMillis = dateMillis, onChange = { dateMillis = it })

                OutlinedTextField(
                    value = odometer,
                    onValueChange = { odometer = sanitizeDecimal(it) },
                    label = { Text("Odometer (${system.distanceUnit})") },
                    singleLine = true,
                    isError = attemptedSave && (odoError || odoRegresses),
                    supportingText = {
                        when {
                            attemptedSave && odoError -> Text("Enter the odometer reading.")
                            odoRegresses -> Text(
                                "Lower than the previous reading (${Format.distance(system, priorOdometer ?: 0.0)}). " +
                                    "Saved, but this segment's economy will be flagged.",
                                color = brand.warn
                            )
                            priorOdometer != null -> Text("Previous: ${Format.distance(system, priorOdometer)}")
                        }
                    },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.fillMaxWidth()
                )

                OutlinedTextField(
                    value = volume,
                    onValueChange = { volume = sanitizeDecimal(it); recompute() },
                    label = { Text("Volume (${system.volumeUnit})") },
                    singleLine = true,
                    isError = attemptedSave && volError,
                    supportingText = {
                        if (attemptedSave && volError) Text("Enter how much fuel was added.")
                    },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.fillMaxWidth()
                )

                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    OutlinedTextField(
                        value = price,
                        onValueChange = { price = sanitizeDecimal(it); lastEdited = "price"; recompute() },
                        label = { Text("Price${system.priceUnit}") },
                        singleLine = true,
                        isError = attemptedSave && priceError,
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        modifier = Modifier.weight(1f)
                    )
                    OutlinedTextField(
                        value = total,
                        onValueChange = { total = sanitizeDecimal(it); lastEdited = "total"; recompute() },
                        label = { Text("Total") },
                        singleLine = true,
                        isError = attemptedSave && totalError,
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        modifier = Modifier.weight(1f)
                    )
                }
                if (attemptedSave && moneyMissing) {
                    Text(
                        "Enter a price or a total — Transit computes the other.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.error
                    )
                } else {
                    Text(
                        "Enter either price or total; the other fills in automatically.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = brand.textTertiary
                    )
                }

                ToggleRow(
                    title = "Full tank",
                    subtitle = "Economy is measured between full tanks.",
                    checked = isFull,
                    onChange = { isFull = it }
                )
                ToggleRow(
                    title = "A previous fill was missed",
                    subtitle = "Flags this segment so a bad number isn't computed.",
                    checked = missedPrev,
                    onChange = { missedPrev = it }
                )

                OutlinedTextField(
                    value = station,
                    onValueChange = { station = it.take(60) },
                    label = { Text("Station (optional)") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = notes,
                    onValueChange = { notes = it.take(280) },
                    label = { Text("Notes (optional)") },
                    modifier = Modifier.fillMaxWidth().height(100.dp)
                )

                Spacer(Modifier.height(2.dp))
                InkButton(
                    text = if (isEditing) "Save changes" else "Add fill-up",
                    onClick = { save() },
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(Modifier.height(24.dp))
            }
        }
    }
}

@Composable
private fun DateField(dateMillis: Long, onChange: (Long) -> Unit) {
    val brand = LocalBrand.current
    GlassCard(modifier = Modifier.fillMaxWidth()) {
        Column {
            Text(
                "Date",
                style = MaterialTheme.typography.labelMedium,
                color = brand.textTertiary,
                fontWeight = FontWeight.SemiBold
            )
            Spacer(Modifier.height(4.dp))
            Text(
                Format.date(dateMillis),
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onBackground,
                fontWeight = FontWeight.SemiBold
            )
            Spacer(Modifier.height(10.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                StepButton("− Day") { onChange(shiftDays(dateMillis, -1)) }
                StepButton("+ Day") { onChange(shiftDays(dateMillis, 1)) }
                StepButton("Today") { onChange(System.currentTimeMillis()) }
            }
        }
    }
}

@Composable
private fun StepButton(label: String, onClick: () -> Unit) {
    val brand = LocalBrand.current
    Box(
        modifier = Modifier
            .height(40.dp)
            .clip(RoundedCornerShape(10.dp))
            .background(brand.glass)
            .clickable(role = Role.Button, onClick = onClick)
            .padding(horizontal = 14.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            label,
            style = MaterialTheme.typography.labelLarge,
            color = MaterialTheme.colorScheme.onBackground,
            fontWeight = FontWeight.Medium
        )
    }
}

@Composable
private fun ToggleRow(
    title: String,
    subtitle: String,
    checked: Boolean,
    onChange: (Boolean) -> Unit
) {
    val brand = LocalBrand.current
    GlassCard(modifier = Modifier.fillMaxWidth()) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    title,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onBackground,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = brand.textSecondary
                )
            }
            Switch(
                checked = checked,
                onCheckedChange = onChange,
                colors = SwitchDefaults.colors(
                    checkedTrackColor = brand.live,
                    checkedThumbColor = Color.White
                )
            )
        }
    }
}

private fun shiftDays(millis: Long, days: Int): Long {
    val cal = Calendar.getInstance()
    cal.timeInMillis = millis
    cal.add(Calendar.DAY_OF_YEAR, days)
    // Never let a fill be dated in the future.
    return cal.timeInMillis.coerceAtMost(System.currentTimeMillis())
}
