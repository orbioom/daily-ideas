package com.orbioom.transit.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.orbioom.transit.domain.Economy
import com.orbioom.transit.domain.FillUp
import com.orbioom.transit.domain.Format
import com.orbioom.transit.domain.UnitSystem
import com.orbioom.transit.domain.VehicleStats
import com.orbioom.transit.ui.components.ChartLegend
import com.orbioom.transit.ui.components.GlassCard
import com.orbioom.transit.ui.components.InkButton
import com.orbioom.transit.ui.components.MistBackground
import com.orbioom.transit.ui.components.StatTile
import com.orbioom.transit.ui.components.TrendChart
import com.orbioom.transit.ui.components.TrendPoint
import com.orbioom.transit.ui.theme.LocalBrand
import com.orbioom.transit.viewmodel.TransitViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VehicleDetailScreen(
    vehicleId: String,
    viewModel: TransitViewModel,
    onBack: () -> Unit,
    onEditVehicle: () -> Unit,
    onAddFill: () -> Unit,
    onEditFill: (String) -> Unit
) {
    val statsFlow = remember(vehicleId) { viewModel.vehicleStatsFlow(vehicleId) }
    val stats by statsFlow.collectAsStateWithLifecycle()

    // If the vehicle vanished (deleted from the edit screen), leave cleanly.
    LaunchedEffect(stats) {
        if (stats == null) onBack()
    }

    var pendingFillDelete by rememberSaveable { mutableStateOf<String?>(null) }
    var showVehicleDelete by rememberSaveable { mutableStateOf(false) }

    val current = stats
    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        current?.vehicle?.name ?: "Vehicle",
                        fontWeight = FontWeight.Bold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = onEditVehicle) {
                        Icon(Icons.Filled.Edit, contentDescription = "Edit vehicle")
                    }
                    IconButton(onClick = { showVehicleDelete = true }) {
                        Icon(Icons.Filled.Delete, contentDescription = "Delete vehicle")
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
            Box(modifier = Modifier.fillMaxSize().padding(padding)) {
                if (current == null) {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text(
                            "Loading…",
                            style = MaterialTheme.typography.bodyMedium,
                            color = LocalBrand.current.textSecondary
                        )
                    }
                } else {
                    DetailContent(
                        stats = current,
                        onEditFill = onEditFill,
                        onRequestDeleteFill = { pendingFillDelete = it }
                    )
                    InkButton(
                        text = "Add fill-up",
                        icon = Icons.Filled.Add,
                        onClick = onAddFill,
                        modifier = Modifier
                            .align(Alignment.BottomEnd)
                            .padding(16.dp)
                    )
                }
            }
        }
    }

    pendingFillDelete?.let { id ->
        ConfirmDialog(
            title = "Delete this fill-up?",
            body = "This removes the fill from the log and recomputes economy. It can't be undone.",
            confirmLabel = "Delete",
            onConfirm = {
                viewModel.deleteFill(id)
                pendingFillDelete = null
            },
            onDismiss = { pendingFillDelete = null }
        )
    }

    if (showVehicleDelete && current != null) {
        ConfirmDialog(
            title = "Delete ${current.vehicle.name}?",
            body = "This removes the vehicle and all ${current.fillCount} of its fill-ups. It can't be undone.",
            confirmLabel = "Delete",
            onConfirm = {
                showVehicleDelete = false
                viewModel.deleteVehicle(current.vehicle.id)
                // LaunchedEffect on null stats will pop back.
            },
            onDismiss = { showVehicleDelete = false }
        )
    }
}

@Composable
private fun DetailContent(
    stats: VehicleStats,
    onEditFill: (String) -> Unit,
    onRequestDeleteFill: (String) -> Unit
) {
    val brand = LocalBrand.current
    val system = stats.vehicle.unitSystem
    val fillsSorted = remember(stats) { stats.fillsDescending() }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 6.dp, bottom = 96.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item(key = "headline") { HeadlineStats(stats) }
        item(key = "chart") { TrendSection(stats) }
        item(key = "history-header") {
            Text(
                "History",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onBackground,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(top = 4.dp)
            )
        }
        if (fillsSorted.isEmpty()) {
            item(key = "history-empty") {
                GlassCard(modifier = Modifier.fillMaxWidth()) {
                    Column {
                        Text(
                            "No fill-ups yet",
                            style = MaterialTheme.typography.titleMedium,
                            color = MaterialTheme.colorScheme.onBackground,
                            fontWeight = FontWeight.SemiBold
                        )
                        Spacer(Modifier.height(4.dp))
                        Text(
                            "Add a fill-up to start tracking economy between full tanks.",
                            style = MaterialTheme.typography.bodyMedium,
                            color = brand.textSecondary
                        )
                    }
                }
            }
        } else {
            items(fillsSorted, key = { it.id }) { fill ->
                val seg = stats.allSegments.firstOrNull { it.endFillId == fill.id }
                FillRow(
                    fill = fill,
                    system = system,
                    segment = seg,
                    onEdit = { onEditFill(fill.id) },
                    onDelete = { onRequestDeleteFill(fill.id) }
                )
            }
        }
    }
}

/** Newest-first list of this vehicle's fills for the history section. */
private fun VehicleStats.fillsDescending(): List<FillUp> =
    sourceFills.sortedWith(compareByDescending<FillUp> { it.date }.thenByDescending { it.odometer })

@Composable
private fun HeadlineStats(stats: VehicleStats) {
    val system = stats.vehicle.unitSystem
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            StatTile(
                label = "Avg economy",
                value = Format.economy(system, stats.averageEconomy),
                accent = stats.hasComputedEconomy,
                modifier = Modifier.weight(1f)
            )
            StatTile(
                label = "Cost / ${system.distanceUnit}",
                value = Format.costPerDistance(system, stats.costPerDistance),
                modifier = Modifier.weight(1f)
            )
        }
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            StatTile(
                label = "Best",
                value = Format.economy(system, stats.bestEconomy),
                modifier = Modifier.weight(1f)
            )
            StatTile(
                label = "Worst",
                value = Format.economy(system, stats.worstEconomy),
                modifier = Modifier.weight(1f)
            )
        }
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            StatTile(
                label = "Total spend",
                value = Format.money(stats.totalSpend),
                modifier = Modifier.weight(1f)
            )
            StatTile(
                label = "Distance",
                value = Format.distance(system, stats.totalDistance),
                modifier = Modifier.weight(1f)
            )
        }
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            StatTile(
                label = "Total fuel",
                value = Format.volume(system, stats.totalVolume),
                modifier = Modifier.weight(1f)
            )
            StatTile(
                label = "Avg price",
                value = Format.price(system, stats.averagePrice),
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
private fun TrendSection(stats: VehicleStats) {
    val brand = LocalBrand.current
    val system = stats.vehicle.unitSystem
    val comp = stats.computableSegments

    Column {
        Text(
            "Trends",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onBackground,
            fontWeight = FontWeight.Bold
        )
        Spacer(Modifier.height(8.dp))

        // Economy over time.
        val ecoTrend = comp.let { segs ->
            if (segs.size < 2) emptyList()
            else segs.mapIndexed { i, s ->
                TrendPoint(
                    x = i.toFloat() / (segs.size - 1).toFloat(),
                    value = s.economy!!.toFloat(),
                    label = Format.shortDate(s.endDate)
                )
            }
        }
        val ecoDesc = if (ecoTrend.size < 2) {
            "Economy trend: not enough full-tank segments to chart yet."
        } else {
            "Economy trend over ${ecoTrend.size} segments, in ${system.economyUnit}. " +
                "Average ${Format.economy(system, stats.averageEconomy)}, " +
                "best ${Format.economy(system, stats.bestEconomy)}, " +
                "worst ${Format.economy(system, stats.worstEconomy)}."
        }
        TrendChart(
            points = ecoTrend,
            lineColor = brand.live,
            contentDescription = ecoDesc
        )
        Spacer(Modifier.height(6.dp))
        ChartLegend(items = listOf("Economy (${system.economyUnit})" to brand.live))

        Spacer(Modifier.height(14.dp))

        // Price over time across all fills.
        val priceTrend = stats.sourceFills
            .sortedBy { it.date }
            .let { fills ->
                if (fills.size < 2) emptyList()
                else fills.mapIndexed { i, f ->
                    TrendPoint(
                        x = i.toFloat() / (fills.size - 1).toFloat(),
                        value = f.pricePerUnit.toFloat(),
                        label = Format.shortDate(f.date)
                    )
                }
            }
        val priceDesc = if (priceTrend.size < 2) {
            "Price trend: not enough fills to chart yet."
        } else {
            "Fuel price trend over ${priceTrend.size} fills. " +
                "Average ${Format.price(system, stats.averagePrice)}."
        }
        TrendChart(
            points = priceTrend,
            lineColor = MaterialTheme.colorScheme.primary,
            contentDescription = priceDesc
        )
        Spacer(Modifier.height(6.dp))
        ChartLegend(items = listOf("Price ($${system.priceUnit})" to MaterialTheme.colorScheme.primary))
    }
}

@Composable
private fun FillRow(
    fill: FillUp,
    system: UnitSystem,
    segment: Economy.Segment?,
    onEdit: () -> Unit,
    onDelete: () -> Unit
) {
    val brand = LocalBrand.current
    GlassCard(
        modifier = Modifier.fillMaxWidth(),
        onClick = onEdit,
        onClickLabel = "Edit fill from ${Format.date(fill.date)}"
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = Format.date(fill.date),
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.onBackground,
                        fontWeight = FontWeight.SemiBold
                    )
                    if (!fill.isFullTank) {
                        Spacer(Modifier.width(8.dp))
                        Tag("Partial", brand.textTertiary)
                    }
                    if (fill.isMissedPrevious) {
                        Spacer(Modifier.width(6.dp))
                        Tag("Missed prev.", brand.warn)
                    }
                }
                Spacer(Modifier.height(4.dp))
                Text(
                    text = "${Format.volume(system, fill.volume)} · ${Format.money(fill.totalCost)} · ${Format.price(system, fill.pricePerUnit)}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = brand.textSecondary
                )
                Text(
                    text = "Odometer ${Format.distance(system, fill.odometer)}" +
                        if (fill.station.isNotBlank()) " · ${fill.station}" else "",
                    style = MaterialTheme.typography.bodyMedium,
                    color = brand.textTertiary
                )
                EconomyLine(system, segment, brand)
                if (fill.notes.isNotBlank()) {
                    Spacer(Modifier.height(2.dp))
                    Text(
                        text = fill.notes,
                        style = MaterialTheme.typography.bodyMedium,
                        color = brand.textSecondary,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
            IconButton(onClick = onDelete) {
                Icon(
                    Icons.Filled.Delete,
                    contentDescription = "Delete fill from ${Format.date(fill.date)}",
                    tint = brand.textTertiary
                )
            }
        }
    }
}

@Composable
private fun EconomyLine(
    system: UnitSystem,
    segment: Economy.Segment?,
    brand: com.orbioom.transit.ui.theme.TransitBrand
) {
    if (segment == null) return
    Spacer(Modifier.height(4.dp))
    if (segment.computable && segment.economy != null) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = "${Format.economy(system, segment.economy)} over ${Format.distance(system, segment.distance)}",
                style = MaterialTheme.typography.bodyMedium,
                color = brand.live,
                fontWeight = FontWeight.SemiBold
            )
        }
    } else if (segment.skipReason != null && segment.skipReason != Economy.SkipReason.FIRST_FULL) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(
                Icons.Filled.Warning,
                contentDescription = null,
                tint = brand.warn,
                modifier = Modifier.size(14.dp)
            )
            Spacer(Modifier.width(4.dp))
            Text(
                text = "Economy not computed — ${segment.skipReason.label}",
                style = MaterialTheme.typography.bodyMedium,
                color = brand.warn
            )
        }
    }
}

@Composable
private fun Tag(text: String, color: Color) {
    Text(
        text = text.uppercase(),
        style = MaterialTheme.typography.labelMedium,
        color = color,
        fontWeight = FontWeight.SemiBold
    )
}

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
        title = { Text(title, fontWeight = FontWeight.Bold) },
        text = { Text(body) },
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
