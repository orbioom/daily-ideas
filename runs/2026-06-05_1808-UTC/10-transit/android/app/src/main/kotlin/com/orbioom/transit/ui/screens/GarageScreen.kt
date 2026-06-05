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
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material.icons.filled.Insights
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.CircularProgressIndicator
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
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.orbioom.transit.domain.Format
import com.orbioom.transit.ui.components.GlassCard
import com.orbioom.transit.ui.components.InkButton
import com.orbioom.transit.ui.components.LiveDot
import com.orbioom.transit.ui.components.MistBackground
import com.orbioom.transit.ui.theme.LocalBrand
import com.orbioom.transit.viewmodel.GarageUiState
import com.orbioom.transit.viewmodel.TransitViewModel
import com.orbioom.transit.viewmodel.VehicleCard

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GarageScreen(
    viewModel: TransitViewModel,
    onOpenVehicle: (String) -> Unit,
    onAddVehicle: () -> Unit,
    onOpenInsights: () -> Unit,
    onOpenSettings: () -> Unit
) {
    val state by viewModel.garageState.collectAsStateWithLifecycle()

    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            TopAppBar(
                title = { Text("Transit", fontWeight = FontWeight.Bold) },
                actions = {
                    IconButton(onClick = onOpenInsights) {
                        Icon(Icons.Filled.Insights, contentDescription = "Insights")
                    }
                    IconButton(onClick = onOpenSettings) {
                        Icon(Icons.Filled.Settings, contentDescription = "Settings")
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
                when (val s = state) {
                    is GarageUiState.Loading -> LoadingState()
                    is GarageUiState.Empty -> EmptyGarageState(onAddVehicle)
                    is GarageUiState.Content -> GarageList(s.cards, onOpenVehicle)
                }

                if (state is GarageUiState.Content) {
                    InkButton(
                        text = "Add vehicle",
                        icon = Icons.Filled.Add,
                        onClick = onAddVehicle,
                        modifier = Modifier
                            .align(Alignment.BottomEnd)
                            .padding(16.dp)
                    )
                }
            }
        }
    }
}

@Composable
private fun GarageList(cards: List<VehicleCard>, onOpen: (String) -> Unit) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 6.dp, bottom = 96.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        items(cards, key = { it.vehicle.id }) { card ->
            VehicleRow(card = card, onOpen = { onOpen(card.vehicle.id) })
        }
    }
}

@Composable
private fun VehicleRow(card: VehicleCard, onOpen: () -> Unit) {
    val brand = LocalBrand.current
    val v = card.vehicle
    val stats = card.stats
    GlassCard(
        modifier = Modifier.fillMaxWidth(),
        onClick = onOpen,
        onClickLabel = "Open ${v.name}"
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(
                Icons.Filled.DirectionsCar,
                contentDescription = null,
                tint = brand.textTertiary,
                modifier = Modifier.size(28.dp)
            )
            Spacer(Modifier.width(14.dp))
            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = v.name,
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.onBackground,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    if (stats.hasComputedEconomy) {
                        Spacer(Modifier.width(8.dp))
                        LiveDot()
                    }
                }
                if (v.makeModel.isNotBlank()) {
                    Text(
                        text = v.makeModel,
                        style = MaterialTheme.typography.bodyMedium,
                        color = brand.textSecondary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
                Spacer(Modifier.height(6.dp))
                val avg = Format.economy(v.unitSystem, stats.averageEconomy)
                val last = stats.lastFill?.let { "Last fill ${Format.shortDate(it.date)}" }
                    ?: "No fills yet"
                Text(
                    text = "Avg $avg  ·  $last  ·  ${stats.fillCount} fill${if (stats.fillCount == 1) "" else "s"}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = brand.textSecondary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
    }
}

@Composable
private fun LoadingState() {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        CircularProgressIndicator(color = MaterialTheme.colorScheme.primary)
    }
}

@Composable
private fun EmptyGarageState(onAdd: () -> Unit) {
    val brand = LocalBrand.current
    Column(
        modifier = Modifier.fillMaxSize().padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            Icons.Filled.DirectionsCar,
            contentDescription = null,
            tint = brand.textTertiary,
            modifier = Modifier.size(56.dp)
        )
        Spacer(Modifier.height(14.dp))
        Text(
            "Your garage is empty",
            style = MaterialTheme.typography.titleLarge,
            color = MaterialTheme.colorScheme.onBackground,
            fontWeight = FontWeight.SemiBold
        )
        Spacer(Modifier.height(6.dp))
        Text(
            "Add a vehicle, then log its fill-ups. Transit turns the numbers into real fuel-economy insight.",
            style = MaterialTheme.typography.bodyMedium,
            color = brand.textSecondary
        )
        Spacer(Modifier.height(18.dp))
        InkButton(text = "Add your first vehicle", icon = Icons.Filled.Add, onClick = onAdd)
    }
}
