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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Insights
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.orbioom.transit.domain.Format
import com.orbioom.transit.domain.VehicleStats
import com.orbioom.transit.ui.components.GlassCard
import com.orbioom.transit.ui.components.StatTile
import com.orbioom.transit.ui.components.MistBackground
import com.orbioom.transit.ui.theme.LocalBrand
import com.orbioom.transit.viewmodel.InsightsState
import com.orbioom.transit.viewmodel.TransitViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InsightsScreen(
    viewModel: TransitViewModel,
    onBack: () -> Unit,
    onOpenVehicle: (String) -> Unit
) {
    val insights by viewModel.insights.collectAsStateWithLifecycle()
    val loaded by viewModel.loaded.collectAsStateWithLifecycle()

    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            TopAppBar(
                title = { Text("Insights", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
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
                val data = insights
                when {
                    !loaded -> { /* brief; garage handles primary loading */ }
                    data == null -> EmptyInsights()
                    else -> InsightsContent(data, onOpenVehicle)
                }
            }
        }
    }
}

@Composable
private fun InsightsContent(data: InsightsState, onOpenVehicle: (String) -> Unit) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item(key = "totals-title") {
            Text(
                "Across your garage",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onBackground,
                fontWeight = FontWeight.Bold
            )
        }
        item(key = "totals-1") {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                StatTile("Total spend", Format.money(data.totalSpend), modifier = Modifier.weight(1f))
                StatTile("Vehicles", data.vehicleCount.toString(), modifier = Modifier.weight(1f))
            }
        }
        item(key = "totals-2") {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                StatTile("Fill-ups", data.fillCount.toString(), modifier = Modifier.weight(1f))
                StatTile(
                    "Fuel logged",
                    Format.number(data.totalVolume, 0),
                    modifier = Modifier.weight(1f)
                )
            }
        }

        item(key = "records-title") {
            Text(
                "Records",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onBackground,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(top = 4.dp)
            )
        }
        item(key = "record-most") {
            RecordCard(
                title = "Most efficient",
                stats = data.mostEfficient,
                valueOf = { Format.economy(it.vehicle.unitSystem, it.averageEconomy) },
                onOpen = onOpenVehicle
            )
        }
        item(key = "record-least") {
            RecordCard(
                title = "Least efficient",
                stats = data.leastEfficient,
                valueOf = { Format.economy(it.vehicle.unitSystem, it.averageEconomy) },
                onOpen = onOpenVehicle
            )
        }
        item(key = "record-cheap") {
            RecordCard(
                title = "Cheapest per distance",
                stats = data.cheapestPerDistance,
                valueOf = { Format.costPerDistance(it.vehicle.unitSystem, it.costPerDistance) },
                onOpen = onOpenVehicle
            )
        }

        item(key = "per-vehicle-title") {
            Text(
                "Every vehicle",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onBackground,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(top = 4.dp)
            )
        }
        items(data.perVehicle, key = { it.vehicle.id }) { stats ->
            PerVehicleCard(stats = stats, onOpen = { onOpenVehicle(stats.vehicle.id) })
        }
    }
}

@Composable
private fun RecordCard(
    title: String,
    stats: VehicleStats?,
    valueOf: (VehicleStats) -> String,
    onOpen: (String) -> Unit
) {
    val brand = LocalBrand.current
    GlassCard(
        modifier = Modifier.fillMaxWidth(),
        onClick = stats?.let { { onOpen(it.vehicle.id) } },
        onClickLabel = stats?.let { "Open ${it.vehicle.name}" }
    ) {
        Column {
            Text(
                title.uppercase(),
                style = MaterialTheme.typography.labelMedium,
                color = brand.textTertiary,
                fontWeight = FontWeight.SemiBold
            )
            Spacer(Modifier.height(4.dp))
            if (stats == null) {
                Text(
                    "Not enough data yet",
                    style = MaterialTheme.typography.titleMedium,
                    color = brand.textSecondary
                )
            } else {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        stats.vehicle.name,
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.onBackground,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.weight(1f)
                    )
                    Text(
                        valueOf(stats),
                        style = MaterialTheme.typography.titleMedium,
                        color = brand.live,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}

@Composable
private fun PerVehicleCard(stats: VehicleStats, onOpen: () -> Unit) {
    val brand = LocalBrand.current
    val system = stats.vehicle.unitSystem
    GlassCard(
        modifier = Modifier.fillMaxWidth(),
        onClick = onOpen,
        onClickLabel = "Open ${stats.vehicle.name}"
    ) {
        Column {
            Text(
                stats.vehicle.name,
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onBackground,
                fontWeight = FontWeight.Bold
            )
            Spacer(Modifier.height(4.dp))
            Text(
                "Avg ${Format.economy(system, stats.averageEconomy)} · " +
                    "${Format.money(stats.totalSpend)} · ${Format.distance(system, stats.totalDistance)}",
                style = MaterialTheme.typography.bodyMedium,
                color = brand.textSecondary
            )
        }
    }
}

@Composable
private fun EmptyInsights() {
    val brand = LocalBrand.current
    Column(
        modifier = Modifier.fillMaxSize().padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            Icons.Filled.Insights,
            contentDescription = null,
            tint = brand.textTertiary,
            modifier = Modifier.size(56.dp)
        )
        Spacer(Modifier.height(14.dp))
        Text(
            "Nothing to compare yet",
            style = MaterialTheme.typography.titleLarge,
            color = MaterialTheme.colorScheme.onBackground,
            fontWeight = FontWeight.SemiBold
        )
        Spacer(Modifier.height(6.dp))
        Text(
            "Add a vehicle and log a few fill-ups. Records and cross-vehicle trends appear here.",
            style = MaterialTheme.typography.bodyMedium,
            color = brand.textSecondary
        )
    }
}
