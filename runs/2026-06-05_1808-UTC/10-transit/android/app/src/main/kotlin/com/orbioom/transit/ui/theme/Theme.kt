package com.orbioom.transit.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

/** Brand extras Material 3 doesn't model: the ink gradient, glass tints, the live accent. */
data class TransitBrand(
    val inkGradient: Brush,
    val glass: Color,
    val glassBorder: Color,
    val live: Color,
    val magic: Color,
    val warn: Color,
    val textSecondary: Color,
    val textTertiary: Color,
    val mistTop: Color,
    val mistBottom: Color
)

val LocalBrand = staticCompositionLocalOf {
    TransitBrand(
        inkGradient = Brush.verticalGradient(listOf(InkTop, InkBottom)),
        glass = Color.White.copy(alpha = 0.42f),
        glassBorder = Color.White.copy(alpha = 0.75f),
        live = LiveGreen,
        magic = MagicGreen,
        warn = WarnAmber,
        textSecondary = TextSecondary,
        textTertiary = TextTertiary,
        mistTop = Mist1,
        mistBottom = Mist3
    )
}

private val LightColors = lightColorScheme(
    primary = InkBottom,
    onPrimary = Color.White,
    secondary = TextSecondary,
    onSecondary = Color.White,
    background = Mist1,
    onBackground = TextInk,
    surface = Mist3,
    onSurface = TextInk,
    surfaceVariant = Mist2,
    onSurfaceVariant = TextSecondary,
    outline = TextTertiary,
    error = Color(0xFFB4453C),
    onError = Color.White
)

private val DarkColors = darkColorScheme(
    primary = Color(0xFFCBD0E0),
    onPrimary = InkBottom,
    secondary = DarkTextSecondary,
    onSecondary = DarkBg1,
    background = DarkBg1,
    onBackground = DarkTextInk,
    surface = DarkSurface,
    onSurface = DarkTextInk,
    surfaceVariant = DarkBg2,
    onSurfaceVariant = DarkTextSecondary,
    outline = DarkTextTertiary,
    error = Color(0xFFE99086),
    onError = DarkBg1
)

@Composable
fun TransitTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colors = if (darkTheme) DarkColors else LightColors

    val brand = TransitBrand(
        inkGradient = Brush.verticalGradient(listOf(InkTop, InkBottom)),
        glass = if (darkTheme) Color.White.copy(alpha = 0.06f) else Color.White.copy(alpha = 0.50f),
        glassBorder = if (darkTheme) Color.White.copy(alpha = 0.10f) else Color.White.copy(alpha = 0.80f),
        live = LiveGreen,
        magic = MagicGreen,
        warn = if (darkTheme) WarnAmberDark else WarnAmber,
        textSecondary = if (darkTheme) DarkTextSecondary else TextSecondary,
        textTertiary = if (darkTheme) DarkTextTertiary else TextTertiary,
        mistTop = if (darkTheme) DarkBg1 else Mist1,
        mistBottom = if (darkTheme) DarkBg2 else Mist3
    )

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as? Activity)?.window ?: return@SideEffect
            window.statusBarColor = (if (darkTheme) DarkBg1 else Mist1).toArgb()
            window.navigationBarColor = (if (darkTheme) DarkBg1 else Mist1).toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
        }
    }

    CompositionLocalProvider(LocalBrand provides brand) {
        MaterialTheme(
            colorScheme = colors,
            typography = TransitTypography,
            content = content
        )
    }
}
