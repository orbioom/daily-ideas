package com.orbioom.meeple.ui.navigation

import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Casino
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.History
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.orbioom.meeple.ui.components.MeepleEasing
import com.orbioom.meeple.ui.components.MistBackground
import com.orbioom.meeple.ui.components.rememberMotionEnabled
import com.orbioom.meeple.ui.screens.GameDetailScreen
import com.orbioom.meeple.ui.screens.GamesScreen
import com.orbioom.meeple.ui.screens.AddEditGameScreen
import com.orbioom.meeple.ui.screens.AddEditPlayScreen
import com.orbioom.meeple.ui.screens.AddEditPlayerScreen
import com.orbioom.meeple.ui.screens.InsightsScreen
import com.orbioom.meeple.ui.screens.PlayDetailScreen
import com.orbioom.meeple.ui.screens.PlayerDetailScreen
import com.orbioom.meeple.ui.screens.PlayersScreen
import com.orbioom.meeple.ui.screens.PlaysScreen
import com.orbioom.meeple.ui.screens.SettingsScreen
import com.orbioom.meeple.ui.theme.LocalBrand
import com.orbioom.meeple.viewmodel.MeepleViewModel
import com.orbioom.meeple.viewmodel.SettingsViewModel

/** Central route table — typed helpers so call sites never hand-build path strings. */
object Routes {
    const val PLAYS = "plays"
    const val GAMES = "games"
    const val PLAYERS = "players"
    const val INSIGHTS = "insights"
    const val SETTINGS = "settings"

    const val GAME_DETAIL = "game_detail/{id}"
    const val GAME_NEW = "game_new"
    const val GAME_EDIT = "game_edit/{id}"

    const val PLAYER_DETAIL = "player_detail/{id}"
    const val PLAYER_NEW = "player_new"
    const val PLAYER_EDIT = "player_edit/{id}"

    const val PLAY_DETAIL = "play_detail/{id}"
    const val PLAY_NEW = "play_new"
    const val PLAY_NEW_FOR_GAME = "play_new_for_game/{gameId}"
    const val PLAY_EDIT = "play_edit/{id}"

    fun gameDetail(id: String) = "game_detail/$id"
    fun gameEdit(id: String) = "game_edit/$id"
    fun playerDetail(id: String) = "player_detail/$id"
    fun playerEdit(id: String) = "player_edit/$id"
    fun playDetail(id: String) = "play_detail/$id"
    fun playNewForGame(gameId: String) = "play_new_for_game/$gameId"
    fun playEdit(id: String) = "play_edit/$id"
}

private data class Tab(val route: String, val label: String, val icon: ImageVector)

private val tabs = listOf(
    Tab(Routes.PLAYS, "Plays", Icons.Filled.History),
    Tab(Routes.GAMES, "Games", Icons.Filled.Casino),
    Tab(Routes.PLAYERS, "Players", Icons.Filled.Groups),
    Tab(Routes.INSIGHTS, "Insights", Icons.Filled.BarChart)
)

@Composable
fun MeepleNavHost(
    meepleViewModel: MeepleViewModel,
    settingsViewModel: SettingsViewModel,
    navController: NavHostController = rememberNavController()
) {
    val motion = rememberMotionEnabled()
    val dur = if (motion) 320 else 0

    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route
    val showBottomBar = currentRoute in tabs.map { it.route }

    Scaffold(
        containerColor = Color.Transparent,
        bottomBar = {
            if (showBottomBar) {
                MeepleBottomBar(navController = navController, currentRoute = currentRoute)
            }
        }
    ) { scaffoldPadding ->
        MistBackground {
            NavHost(
                navController = navController,
                startDestination = Routes.PLAYS,
                modifier = Modifier
                    .fillMaxSize()
                    .padding(scaffoldPadding),
                enterTransition = {
                    slideInHorizontally(animationSpec = tween(dur, easing = MeepleEasing)) { it / 6 } +
                        fadeIn(animationSpec = tween(dur, easing = MeepleEasing))
                },
                exitTransition = {
                    fadeOut(animationSpec = tween(dur, easing = MeepleEasing))
                },
                popEnterTransition = { fadeIn(animationSpec = tween(dur, easing = MeepleEasing)) },
                popExitTransition = {
                    slideOutHorizontally(animationSpec = tween(dur, easing = MeepleEasing)) { it / 6 } +
                        fadeOut(animationSpec = tween(dur, easing = MeepleEasing))
                }
            ) {
                // ---- Tabs ----
                composable(Routes.PLAYS) {
                    PlaysScreen(
                        viewModel = meepleViewModel,
                        onOpenPlay = { id -> navController.navigate(Routes.playDetail(id)) },
                        onLogPlay = { navController.navigate(Routes.PLAY_NEW) },
                        onOpenSettings = { navController.navigate(Routes.SETTINGS) }
                    )
                }
                composable(Routes.GAMES) {
                    GamesScreen(
                        viewModel = meepleViewModel,
                        onOpenGame = { id -> navController.navigate(Routes.gameDetail(id)) },
                        onAddGame = { navController.navigate(Routes.GAME_NEW) },
                        onOpenSettings = { navController.navigate(Routes.SETTINGS) }
                    )
                }
                composable(Routes.PLAYERS) {
                    PlayersScreen(
                        viewModel = meepleViewModel,
                        onOpenPlayer = { id -> navController.navigate(Routes.playerDetail(id)) },
                        onAddPlayer = { navController.navigate(Routes.PLAYER_NEW) },
                        onOpenSettings = { navController.navigate(Routes.SETTINGS) }
                    )
                }
                composable(Routes.INSIGHTS) {
                    InsightsScreen(
                        viewModel = meepleViewModel,
                        onOpenGame = { id -> navController.navigate(Routes.gameDetail(id)) },
                        onOpenPlayer = { id -> navController.navigate(Routes.playerDetail(id)) },
                        onOpenSettings = { navController.navigate(Routes.SETTINGS) }
                    )
                }

                // ---- Game detail / edit ----
                composable(
                    route = Routes.GAME_DETAIL,
                    arguments = listOf(navArgument("id") { type = NavType.StringType })
                ) { entry ->
                    val id = entry.arguments?.getString("id").orEmpty()
                    GameDetailScreen(
                        gameId = id,
                        viewModel = meepleViewModel,
                        onBack = { navController.popBackStack() },
                        onEdit = { navController.navigate(Routes.gameEdit(id)) },
                        onLogPlay = { navController.navigate(Routes.playNewForGame(id)) },
                        onOpenPlay = { pid -> navController.navigate(Routes.playDetail(pid)) },
                        onOpenPlayer = { pid -> navController.navigate(Routes.playerDetail(pid)) }
                    )
                }
                composable(Routes.GAME_NEW) {
                    AddEditGameScreen(
                        gameId = null,
                        viewModel = meepleViewModel,
                        settingsViewModel = settingsViewModel,
                        onDone = { navController.popBackStack() },
                        onCancel = { navController.popBackStack() }
                    )
                }
                composable(
                    route = Routes.GAME_EDIT,
                    arguments = listOf(navArgument("id") { type = NavType.StringType })
                ) { entry ->
                    AddEditGameScreen(
                        gameId = entry.arguments?.getString("id"),
                        viewModel = meepleViewModel,
                        settingsViewModel = settingsViewModel,
                        onDone = { navController.popBackStack() },
                        onCancel = { navController.popBackStack() }
                    )
                }

                // ---- Player detail / edit ----
                composable(
                    route = Routes.PLAYER_DETAIL,
                    arguments = listOf(navArgument("id") { type = NavType.StringType })
                ) { entry ->
                    val id = entry.arguments?.getString("id").orEmpty()
                    PlayerDetailScreen(
                        playerId = id,
                        viewModel = meepleViewModel,
                        onBack = { navController.popBackStack() },
                        onEdit = { navController.navigate(Routes.playerEdit(id)) },
                        onOpenGame = { gid -> navController.navigate(Routes.gameDetail(gid)) },
                        onOpenPlayer = { pid -> navController.navigate(Routes.playerDetail(pid)) }
                    )
                }
                composable(Routes.PLAYER_NEW) {
                    AddEditPlayerScreen(
                        playerId = null,
                        viewModel = meepleViewModel,
                        onDone = { navController.popBackStack() },
                        onCancel = { navController.popBackStack() }
                    )
                }
                composable(
                    route = Routes.PLAYER_EDIT,
                    arguments = listOf(navArgument("id") { type = NavType.StringType })
                ) { entry ->
                    AddEditPlayerScreen(
                        playerId = entry.arguments?.getString("id"),
                        viewModel = meepleViewModel,
                        onDone = { navController.popBackStack() },
                        onCancel = { navController.popBackStack() }
                    )
                }

                // ---- Play detail / log ----
                composable(
                    route = Routes.PLAY_DETAIL,
                    arguments = listOf(navArgument("id") { type = NavType.StringType })
                ) { entry ->
                    val id = entry.arguments?.getString("id").orEmpty()
                    PlayDetailScreen(
                        playId = id,
                        viewModel = meepleViewModel,
                        onBack = { navController.popBackStack() },
                        onEdit = { navController.navigate(Routes.playEdit(id)) },
                        onOpenGame = { gid -> navController.navigate(Routes.gameDetail(gid)) },
                        onOpenPlayer = { pid -> navController.navigate(Routes.playerDetail(pid)) }
                    )
                }
                composable(Routes.PLAY_NEW) {
                    AddEditPlayScreen(
                        playId = null,
                        presetGameId = null,
                        viewModel = meepleViewModel,
                        settingsViewModel = settingsViewModel,
                        onDone = { navController.popBackStack() },
                        onCancel = { navController.popBackStack() },
                        onAddGame = { navController.navigate(Routes.GAME_NEW) },
                        onAddPlayer = { navController.navigate(Routes.PLAYER_NEW) }
                    )
                }
                composable(
                    route = Routes.PLAY_NEW_FOR_GAME,
                    arguments = listOf(navArgument("gameId") { type = NavType.StringType })
                ) { entry ->
                    AddEditPlayScreen(
                        playId = null,
                        presetGameId = entry.arguments?.getString("gameId"),
                        viewModel = meepleViewModel,
                        settingsViewModel = settingsViewModel,
                        onDone = { navController.popBackStack() },
                        onCancel = { navController.popBackStack() },
                        onAddGame = { navController.navigate(Routes.GAME_NEW) },
                        onAddPlayer = { navController.navigate(Routes.PLAYER_NEW) }
                    )
                }
                composable(
                    route = Routes.PLAY_EDIT,
                    arguments = listOf(navArgument("id") { type = NavType.StringType })
                ) { entry ->
                    AddEditPlayScreen(
                        playId = entry.arguments?.getString("id"),
                        presetGameId = null,
                        viewModel = meepleViewModel,
                        settingsViewModel = settingsViewModel,
                        onDone = { navController.popBackStack() },
                        onCancel = { navController.popBackStack() },
                        onAddGame = { navController.navigate(Routes.GAME_NEW) },
                        onAddPlayer = { navController.navigate(Routes.PLAYER_NEW) }
                    )
                }

                // ---- Settings ----
                composable(Routes.SETTINGS) {
                    SettingsScreen(
                        settingsViewModel = settingsViewModel,
                        meepleViewModel = meepleViewModel,
                        onBack = { navController.popBackStack() }
                    )
                }
            }
        }
    }
}

@Composable
private fun MeepleBottomBar(navController: NavHostController, currentRoute: String?) {
    val brand = LocalBrand.current
    NavigationBar(
        containerColor = brand.glass,
        contentColor = MaterialTheme.colorScheme.onBackground
    ) {
        val backStackEntry by navController.currentBackStackEntryAsState()
        tabs.forEach { tab ->
            val selected = backStackEntry?.destination?.hierarchy?.any { it.route == tab.route } == true ||
                currentRoute == tab.route
            NavigationBarItem(
                selected = selected,
                onClick = {
                    navController.navigate(tab.route) {
                        popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                        launchSingleTop = true
                        restoreState = true
                    }
                },
                icon = { Icon(tab.icon, contentDescription = tab.label) },
                label = {
                    Text(
                        tab.label,
                        fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal
                    )
                },
                colors = NavigationBarItemDefaults.colors(
                    selectedIconColor = MaterialTheme.colorScheme.onBackground,
                    selectedTextColor = MaterialTheme.colorScheme.onBackground,
                    indicatorColor = brand.win.copy(alpha = 0.30f),
                    unselectedIconColor = brand.textTertiary,
                    unselectedTextColor = brand.textTertiary
                )
            )
        }
    }
}
