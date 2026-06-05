package com.orbioom.forage

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.orbioom.forage.data.ThemeMode
import com.orbioom.forage.ui.navigation.ForageNavHost
import com.orbioom.forage.ui.theme.ForageTheme
import com.orbioom.forage.viewmodel.RecipeViewModel
import com.orbioom.forage.viewmodel.SettingsViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        setContent { ForageApp() }
    }
}

@Composable
private fun ForageApp() {
    val recipeViewModel: RecipeViewModel = viewModel()
    val settingsViewModel: SettingsViewModel = viewModel()

    val settings by settingsViewModel.settings.collectAsStateWithLifecycle()

    // Apply the persisted default sort exactly once, on first composition.
    var appliedDefaultSort by remember { mutableStateOf(false) }
    LaunchedEffect(settings.sort) {
        if (!appliedDefaultSort) {
            recipeViewModel.applyDefaultSort(settings.sort)
            appliedDefaultSort = true
        }
    }

    val darkTheme = when (settings.theme) {
        ThemeMode.SYSTEM -> isSystemInDarkTheme()
        ThemeMode.LIGHT -> false
        ThemeMode.DARK -> true
    }

    ForageTheme(darkTheme = darkTheme) {
        ForageNavHost(
            recipeViewModel = recipeViewModel,
            settingsViewModel = settingsViewModel
        )
    }
}
