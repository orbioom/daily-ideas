package com.orbioom.transit.ui.navigation

import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.orbioom.transit.ui.components.TransitEasing
import com.orbioom.transit.ui.components.rememberMotionEnabled
import com.orbioom.transit.ui.screens.AddEditFillScreen
import com.orbioom.transit.ui.screens.AddEditVehicleScreen
import com.orbioom.transit.ui.screens.GarageScreen
import com.orbioom.transit.ui.screens.InsightsScreen
import com.orbioom.transit.ui.screens.SettingsScreen
import com.orbioom.transit.ui.screens.VehicleDetailScreen
import com.orbioom.transit.viewmodel.SettingsViewModel
import com.orbioom.transit.viewmodel.TransitViewModel

/** Central route table — typed helpers so call sites never hand-build path strings. */
object Routes {
    const val GARAGE = "garage"
    const val INSIGHTS = "insights"
    const val SETTINGS = "settings"

    const val VEHICLE_NEW = "vehicle_new"
    const val VEHICLE_EDIT = "vehicle_edit/{id}"
    const val DETAIL = "detail/{id}"
    const val FILL_NEW = "fill_new/{vehicleId}"
    const val FILL_EDIT = "fill_edit/{vehicleId}/{fillId}"

    fun vehicleEdit(id: String) = "vehicle_edit/$id"
    fun detail(id: String) = "detail/$id"
    fun fillNew(vehicleId: String) = "fill_new/$vehicleId"
    fun fillEdit(vehicleId: String, fillId: String) = "fill_edit/$vehicleId/$fillId"
}

@Composable
fun TransitNavHost(
    transitViewModel: TransitViewModel,
    settingsViewModel: SettingsViewModel,
    navController: NavHostController = rememberNavController()
) {
    val motion = rememberMotionEnabled()
    val dur = if (motion) 320 else 0

    NavHost(
        navController = navController,
        startDestination = Routes.GARAGE,
        enterTransition = {
            slideInHorizontally(animationSpec = tween(dur, easing = TransitEasing)) { it / 6 } +
                fadeIn(animationSpec = tween(dur, easing = TransitEasing))
        },
        exitTransition = {
            fadeOut(animationSpec = tween(dur, easing = TransitEasing))
        },
        popEnterTransition = { fadeIn(animationSpec = tween(dur, easing = TransitEasing)) },
        popExitTransition = {
            slideOutHorizontally(animationSpec = tween(dur, easing = TransitEasing)) { it / 6 } +
                fadeOut(animationSpec = tween(dur, easing = TransitEasing))
        }
    ) {

        composable(Routes.GARAGE) {
            GarageScreen(
                viewModel = transitViewModel,
                onOpenVehicle = { id -> navController.navigate(Routes.detail(id)) },
                onAddVehicle = { navController.navigate(Routes.VEHICLE_NEW) },
                onOpenInsights = { navController.navigate(Routes.INSIGHTS) },
                onOpenSettings = { navController.navigate(Routes.SETTINGS) }
            )
        }

        composable(Routes.INSIGHTS) {
            InsightsScreen(
                viewModel = transitViewModel,
                onBack = { navController.popBackStack() },
                onOpenVehicle = { id -> navController.navigate(Routes.detail(id)) }
            )
        }

        composable(
            route = Routes.DETAIL,
            arguments = listOf(navArgument("id") { type = NavType.StringType })
        ) { entry ->
            val id = entry.arguments?.getString("id").orEmpty()
            VehicleDetailScreen(
                vehicleId = id,
                viewModel = transitViewModel,
                onBack = { navController.popBackStack() },
                onEditVehicle = { navController.navigate(Routes.vehicleEdit(id)) },
                onAddFill = { navController.navigate(Routes.fillNew(id)) },
                onEditFill = { fillId -> navController.navigate(Routes.fillEdit(id, fillId)) }
            )
        }

        composable(Routes.VEHICLE_NEW) {
            AddEditVehicleScreen(
                vehicleId = null,
                viewModel = transitViewModel,
                settingsViewModel = settingsViewModel,
                onDone = { navController.popBackStack() },
                onCancel = { navController.popBackStack() }
            )
        }

        composable(
            route = Routes.VEHICLE_EDIT,
            arguments = listOf(navArgument("id") { type = NavType.StringType })
        ) { entry ->
            val id = entry.arguments?.getString("id")
            AddEditVehicleScreen(
                vehicleId = id,
                viewModel = transitViewModel,
                settingsViewModel = settingsViewModel,
                onDone = { navController.popBackStack() },
                onCancel = { navController.popBackStack() }
            )
        }

        composable(
            route = Routes.FILL_NEW,
            arguments = listOf(navArgument("vehicleId") { type = NavType.StringType })
        ) { entry ->
            val vehicleId = entry.arguments?.getString("vehicleId").orEmpty()
            AddEditFillScreen(
                vehicleId = vehicleId,
                fillId = null,
                viewModel = transitViewModel,
                onDone = { navController.popBackStack() },
                onCancel = { navController.popBackStack() }
            )
        }

        composable(
            route = Routes.FILL_EDIT,
            arguments = listOf(
                navArgument("vehicleId") { type = NavType.StringType },
                navArgument("fillId") { type = NavType.StringType }
            )
        ) { entry ->
            val vehicleId = entry.arguments?.getString("vehicleId").orEmpty()
            val fillId = entry.arguments?.getString("fillId")
            AddEditFillScreen(
                vehicleId = vehicleId,
                fillId = fillId,
                viewModel = transitViewModel,
                onDone = { navController.popBackStack() },
                onCancel = { navController.popBackStack() }
            )
        }

        composable(Routes.SETTINGS) {
            val settings by settingsViewModel.settings.collectAsStateWithLifecycle()
            val garageState by transitViewModel.garageState.collectAsStateWithLifecycle()
            SettingsScreen(
                settings = settings,
                garageState = garageState,
                onSetTheme = settingsViewModel::setTheme,
                onSetUnit = settingsViewModel::setDefaultUnitSystem,
                onSetDefaultVehicle = settingsViewModel::setDefaultVehicle,
                onResetSample = transitViewModel::resetToSample,
                onClearAll = {
                    transitViewModel.clearAll()
                    settingsViewModel.setDefaultVehicle("")
                },
                onBack = { navController.popBackStack() }
            )
        }
    }
}
