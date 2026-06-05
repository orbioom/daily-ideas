package com.orbioom.frond

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import com.orbioom.frond.ui.screens.PlantListScreen
import com.orbioom.frond.ui.theme.Color_Transparent
import com.orbioom.frond.ui.theme.FrondTheme
import com.orbioom.frond.viewmodel.PlantViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            FrondTheme {
                Surface(modifier = Modifier.fillMaxSize(), color = Color_Transparent) {
                    val vm: PlantViewModel = viewModel()
                    PlantListScreen(vm = vm)
                }
            }
        }
    }
}
