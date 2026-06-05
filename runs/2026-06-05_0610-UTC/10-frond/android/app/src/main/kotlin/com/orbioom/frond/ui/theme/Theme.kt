package com.orbioom.frond.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val OrbScheme = lightColorScheme(
    primary = OrbInk,
    onPrimary = Color.White,
    secondary = OrbLive,
    onSecondary = OrbText,
    background = OrbMist,
    onBackground = OrbText,
    surface = OrbGlass,
    onSurface = OrbText,
    surfaceVariant = OrbGlassSoft,
    onSurfaceVariant = OrbText2,
    outline = OrbText3
)

@Composable
fun FrondTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = OrbScheme,
        typography = OrbTypography,
        content = content
    )
}
