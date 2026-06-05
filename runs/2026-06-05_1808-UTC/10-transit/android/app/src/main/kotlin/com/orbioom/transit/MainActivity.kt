package com.orbioom.transit

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.orbioom.transit.data.ThemeMode
import com.orbioom.transit.ui.navigation.TransitNavHost
import com.orbioom.transit.ui.theme.TransitTheme
import com.orbioom.transit.viewmodel.SettingsViewModel
import com.orbioom.transit.viewmodel.TransitViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        setContent { TransitApp() }
    }
}

@Composable
private fun TransitApp() {
    val transitViewModel: TransitViewModel = viewModel()
    val settingsViewModel: SettingsViewModel = viewModel()

    val settings by settingsViewModel.settings.collectAsStateWithLifecycle()

    val darkTheme = when (settings.theme) {
        ThemeMode.SYSTEM -> isSystemInDarkTheme()
        ThemeMode.LIGHT -> false
        ThemeMode.DARK -> true
    }

    TransitTheme(darkTheme = darkTheme) {
        TransitNavHost(
            transitViewModel = transitViewModel,
            settingsViewModel = settingsViewModel
        )
    }
}
