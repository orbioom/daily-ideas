package com.orbioom.meeple

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.orbioom.meeple.data.ThemeMode
import com.orbioom.meeple.ui.navigation.MeepleNavHost
import com.orbioom.meeple.ui.theme.MeepleTheme
import com.orbioom.meeple.viewmodel.MeepleViewModel
import com.orbioom.meeple.viewmodel.SettingsViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        setContent { MeepleApp() }
    }
}

@Composable
private fun MeepleApp() {
    val meepleViewModel: MeepleViewModel = viewModel()
    val settingsViewModel: SettingsViewModel = viewModel()

    val settings by settingsViewModel.settings.collectAsStateWithLifecycle()

    val darkTheme = when (settings.theme) {
        ThemeMode.SYSTEM -> isSystemInDarkTheme()
        ThemeMode.LIGHT -> false
        ThemeMode.DARK -> true
    }

    MeepleTheme(darkTheme = darkTheme) {
        MeepleNavHost(
            meepleViewModel = meepleViewModel,
            settingsViewModel = settingsViewModel
        )
    }
}
