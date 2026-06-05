package com.orbioom.transit.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.orbioom.transit.domain.FuelType
import com.orbioom.transit.domain.UnitSystem
import com.orbioom.transit.domain.Vehicle
import com.orbioom.transit.ui.components.GlassCard
import com.orbioom.transit.ui.components.InkButton
import com.orbioom.transit.ui.components.MistBackground
import com.orbioom.transit.ui.theme.LocalBrand
import com.orbioom.transit.viewmodel.SettingsViewModel
import com.orbioom.transit.viewmodel.TransitViewModel
import java.util.UUID

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddEditVehicleScreen(
    vehicleId: String?,
    viewModel: TransitViewModel,
    settingsViewModel: SettingsViewModel,
    onDone: () -> Unit,
    onCancel: () -> Unit
) {
    val brand = LocalBrand.current
    val settings by settingsViewModel.settings.collectAsStateWithLifecycle()
    val existing = remember(vehicleId) { vehicleId?.let { viewModel.vehicle(it) } }
    val isEditing = existing != null

    var name by rememberSaveable { mutableStateOf(existing?.name ?: "") }
    var makeModel by rememberSaveable { mutableStateOf(existing?.makeModel ?: "") }
    var unit by rememberSaveable {
        mutableStateOf(existing?.unitSystem ?: settings.defaultUnitSystem)
    }
    var fuelType by rememberSaveable { mutableStateOf(existing?.fuelType ?: FuelType.PETROL) }
    var tank by rememberSaveable {
        mutableStateOf(existing?.tankCapacity?.let { trimNumber(it) } ?: "")
    }
    var notes by rememberSaveable { mutableStateOf(existing?.notes ?: "") }
    var attemptedSave by rememberSaveable { mutableStateOf(false) }

    val nameError = name.isBlank()
    val tankError = tank.isNotBlank() && tank.toDoubleOrNull().let { it == null || it <= 0.0 }
    val canSave = !nameError && !tankError

    fun save() {
        attemptedSave = true
        if (!canSave) return
        val vehicle = Vehicle(
            id = existing?.id ?: "veh-${UUID.randomUUID()}",
            name = name.trim(),
            makeModel = makeModel.trim(),
            unitSystem = unit,
            fuelType = fuelType,
            tankCapacity = tank.toDoubleOrNull()?.takeIf { it > 0.0 },
            notes = notes.trim(),
            createdAt = existing?.createdAt ?: System.currentTimeMillis()
        )
        viewModel.saveVehicle(vehicle)
        onDone()
    }

    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            TopAppBar(
                title = {
                    Text(if (isEditing) "Edit vehicle" else "New vehicle", fontWeight = FontWeight.Bold)
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
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                Spacer(Modifier.height(2.dp))

                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it.take(60) },
                    label = { Text("Name") },
                    singleLine = true,
                    isError = attemptedSave && nameError,
                    supportingText = {
                        if (attemptedSave && nameError) Text("Give the vehicle a name.")
                        else Text("e.g. The Golf")
                    },
                    modifier = Modifier.fillMaxWidth()
                )

                OutlinedTextField(
                    value = makeModel,
                    onValueChange = { makeModel = it.take(80) },
                    label = { Text("Make & model (optional)") },
                    singleLine = true,
                    supportingText = { Text("e.g. VW Golf 1.5 TSI") },
                    modifier = Modifier.fillMaxWidth()
                )

                FieldLabel("Units")
                ChoiceRow(
                    options = UnitSystem.entries.map { it to it.title },
                    selected = unit,
                    onSelect = { unit = it }
                )

                FieldLabel("Fuel type")
                ChoiceRow(
                    options = FuelType.entries.map { it to it.title },
                    selected = fuelType,
                    onSelect = { fuelType = it }
                )

                OutlinedTextField(
                    value = tank,
                    onValueChange = { tank = sanitizeDecimal(it) },
                    label = { Text("Tank capacity (${unit.volumeUnit}, optional)") },
                    singleLine = true,
                    isError = attemptedSave && tankError,
                    supportingText = {
                        if (attemptedSave && tankError) Text("Enter a positive number, or leave blank.")
                    },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.fillMaxWidth()
                )

                OutlinedTextField(
                    value = notes,
                    onValueChange = { notes = it.take(280) },
                    label = { Text("Notes (optional)") },
                    modifier = Modifier.fillMaxWidth().height(110.dp)
                )

                Spacer(Modifier.height(2.dp))
                InkButton(
                    text = if (isEditing) "Save changes" else "Add vehicle",
                    onClick = { save() },
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(Modifier.height(24.dp))
            }
        }
    }
}

@Composable
private fun FieldLabel(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.labelLarge,
        color = LocalBrand.current.textSecondary,
        fontWeight = FontWeight.SemiBold
    )
}

@Composable
private fun <T> ChoiceRow(
    options: List<Pair<T, String>>,
    selected: T,
    onSelect: (T) -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        options.chunked(2).forEach { rowItems ->
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
                rowItems.forEach { (value, label) ->
                    ChoiceChip(
                        label = label,
                        selected = value == selected,
                        onClick = { onSelect(value) },
                        modifier = Modifier.weight(1f)
                    )
                }
                if (rowItems.size == 1) Spacer(Modifier.weight(1f))
            }
        }
    }
}

@Composable
private fun ChoiceChip(
    label: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val brand = LocalBrand.current
    GlassCard(
        modifier = modifier,
        onClick = onClick,
        onClickLabel = label
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = label,
                style = MaterialTheme.typography.labelLarge,
                color = if (selected) brand.live else brand.textSecondary,
                fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium
            )
        }
    }
}

/** Allow only a single well-formed decimal as the user types. */
fun sanitizeDecimal(raw: String): String {
    val filtered = raw.filter { it.isDigit() || it == '.' }
    val firstDot = filtered.indexOf('.')
    return if (firstDot < 0) filtered
    else filtered.substring(0, firstDot + 1) + filtered.substring(firstDot + 1).replace(".", "")
}

/** Trim trailing zeros for editing: 50.0 -> "50". */
fun trimNumber(value: Double): String {
    val s = value.toString()
    return if (s.endsWith(".0")) s.dropLast(2) else s
}
