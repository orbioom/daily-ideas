package com.orbioom.frond.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.outlined.WaterDrop
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.orbioom.frond.data.Plant
import com.orbioom.frond.ui.theme.*
import com.orbioom.frond.viewmodel.PlantViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlantListScreen(vm: PlantViewModel) {
    val plants by vm.plants.collectAsState()
    var showAdd by remember { mutableStateOf(false) }
    val now = System.currentTimeMillis()
    val ordered = remember(plants) { plants.sortedBy { it.daysUntilDue(now) } }
    val dueCount = ordered.count { it.daysUntilDue(now) <= 0 }

    Box(
        Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(listOf(OrbMist, OrbMist2, Color_ECEEF2))
            )
    ) {
        Scaffold(
            containerColor = Color_Transparent,
            floatingActionButton = {
                FloatingActionButton(
                    onClick = { showAdd = true },
                    containerColor = OrbInk,
                    contentColor = Color_White
                ) { Icon(Icons.Filled.Add, contentDescription = "Add plant") }
            }
        ) { pad ->
            Column(Modifier.padding(pad).fillMaxSize().padding(horizontal = 20.dp)) {
                Spacer(Modifier.height(16.dp))
                Text("FROND", style = MaterialTheme.typography.labelSmall, color = OrbText3)
                Text("Your garden",
                    style = MaterialTheme.typography.headlineMedium, color = OrbText)
                Text(
                    if (dueCount == 0) "Everything's watered. Rest easy."
                    else "$dueCount need${if (dueCount == 1) "s" else ""} water today",
                    style = MaterialTheme.typography.bodyMedium, color = OrbText2
                )
                Spacer(Modifier.height(14.dp))

                if (ordered.isEmpty()) {
                    EmptyState()
                } else {
                    LazyColumn(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        items(ordered, key = { it.id }) { plant ->
                            PlantCard(
                                plant = plant,
                                now = now,
                                onWater = { vm.water(plant.id) },
                                onDelete = { vm.delete(plant.id) }
                            )
                        }
                        item { Spacer(Modifier.height(80.dp)) }
                    }
                }
            }
        }
    }

    if (showAdd) {
        AddPlantDialog(
            onDismiss = { showAdd = false },
            onAdd = { name, species, interval ->
                vm.addPlant(name, species, interval)
                showAdd = false
            }
        )
    }
}

@Composable
private fun PlantCard(plant: Plant, now: Long, onWater: () -> Unit, onDelete: () -> Unit) {
    val days = plant.daysUntilDue(now)
    val thirst = plant.thirst(now)
    val (statusText, statusColor) = when {
        days < 0 -> "Overdue ${-days}d" to Color_Warm
        days == 0 -> "Water today" to OrbInk
        days == 1 -> "Tomorrow" to OrbText2
        else -> "In ${days}d" to OrbText2
    }

    Surface(
        color = OrbGlass,
        shape = RoundedCornerShape(20.dp),
        tonalElevation = 0.dp,
        shadowElevation = 6.dp,
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(Modifier.padding(18.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text(plant.name, style = MaterialTheme.typography.titleMedium, color = OrbText)
                    if (plant.species.isNotBlank()) {
                        Text(plant.species, fontSize = 12.sp, color = OrbText3,
                            fontFamily = FontFamily.Monospace)
                    }
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text(statusText, fontWeight = FontWeight.SemiBold, color = statusColor)
                    Text("every ${plant.intervalDays}d", fontSize = 11.sp, color = OrbText3)
                }
            }
            Spacer(Modifier.height(12.dp))
            // thirst bar
            Box(
                Modifier.fillMaxWidth().height(6.dp).clip(RoundedCornerShape(3.dp))
                    .background(Color_TrackSoft)
            ) {
                Box(
                    Modifier.fillMaxWidth(thirst).height(6.dp).clip(RoundedCornerShape(3.dp))
                        .background(if (days < 0) Color_Warm else OrbLive)
                )
            }
            Spacer(Modifier.height(12.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Button(
                    onClick = onWater,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = OrbInk, contentColor = Color_White),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.weight(1f)
                ) {
                    Icon(Icons.Outlined.WaterDrop, contentDescription = null,
                        modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(6.dp))
                    Text("Watered")
                }
                OutlinedButton(
                    onClick = onDelete,
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = OrbText2)
                ) { Text("Remove") }
            }
        }
    }
}

@Composable
private fun EmptyState() {
    Column(
        Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text("🌱", fontSize = 40.sp)
        Spacer(Modifier.height(8.dp))
        Text("Add a plant to begin.", color = OrbText2,
            style = MaterialTheme.typography.bodyMedium)
    }
}
