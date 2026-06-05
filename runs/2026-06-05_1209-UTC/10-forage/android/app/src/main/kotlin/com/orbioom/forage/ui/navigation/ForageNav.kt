package com.orbioom.forage.ui.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.orbioom.forage.ui.screens.RecipeDetailScreen
import com.orbioom.forage.ui.screens.RecipeEditScreen
import com.orbioom.forage.ui.screens.RecipeListScreen
import com.orbioom.forage.ui.screens.SettingsScreen
import com.orbioom.forage.viewmodel.RecipeViewModel
import com.orbioom.forage.viewmodel.SettingsViewModel

/** Central route table — typed helpers so call sites never hand-build path strings. */
object Routes {
    const val LIST = "list"
    const val SETTINGS = "settings"
    const val DETAIL = "detail/{id}"
    const val EDIT_NEW = "edit"
    const val EDIT = "edit/{id}"

    fun detail(id: String) = "detail/$id"
    fun edit(id: String) = "edit/$id"
}

@Composable
fun ForageNavHost(
    recipeViewModel: RecipeViewModel,
    settingsViewModel: SettingsViewModel,
    navController: NavHostController = rememberNavController()
) {
    NavHost(navController = navController, startDestination = Routes.LIST) {

        composable(Routes.LIST) {
            RecipeListScreen(
                viewModel = recipeViewModel,
                onOpenRecipe = { id -> navController.navigate(Routes.detail(id)) },
                onAddRecipe = { navController.navigate(Routes.EDIT_NEW) },
                onOpenSettings = { navController.navigate(Routes.SETTINGS) }
            )
        }

        composable(
            route = Routes.DETAIL,
            arguments = listOf(navArgument("id") { type = NavType.StringType })
        ) { entry ->
            val id = entry.arguments?.getString("id").orEmpty()
            RecipeDetailScreen(
                recipeId = id,
                viewModel = recipeViewModel,
                onBack = { navController.popBackStack() },
                onEdit = { navController.navigate(Routes.edit(id)) }
            )
        }

        composable(Routes.EDIT_NEW) {
            RecipeEditScreen(
                recipeId = null,
                viewModel = recipeViewModel,
                onDone = { navController.popBackStack() },
                onCancel = { navController.popBackStack() }
            )
        }

        composable(
            route = Routes.EDIT,
            arguments = listOf(navArgument("id") { type = NavType.StringType })
        ) { entry ->
            val id = entry.arguments?.getString("id")
            RecipeEditScreen(
                recipeId = id,
                viewModel = recipeViewModel,
                onDone = { navController.popBackStack() },
                onCancel = { navController.popBackStack() }
            )
        }

        composable(Routes.SETTINGS) {
            val settings by settingsViewModel.settings.collectAsStateWithLifecycle()
            SettingsScreen(
                settings = settings,
                onSetTheme = settingsViewModel::setTheme,
                onSetSort = { order ->
                    settingsViewModel.setSort(order)
                    recipeViewModel.setSort(order)
                },
                onResetSample = recipeViewModel::resetToSample,
                onClearAll = recipeViewModel::clearAll,
                onBack = { navController.popBackStack() }
            )
        }
    }
}
