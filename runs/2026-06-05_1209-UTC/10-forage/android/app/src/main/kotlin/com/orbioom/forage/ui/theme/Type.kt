package com.orbioom.forage.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.sp

/**
 * Orbioom uses Manrope (UI) + JetBrains Mono (numbers). Bundling the TTFs is not possible
 * in this environment, so we fall back gracefully to the platform sans-serif and monospace
 * families — wired here in one place so swapping in the real fonts later is a one-file change.
 */
val UiFontFamily = FontFamily.SansSerif
val MonoFontFamily = FontFamily.Monospace

val ForageTypography = Typography(
    headlineLarge = TextStyle(fontFamily = UiFontFamily, fontSize = 30.sp, lineHeight = 36.sp),
    headlineMedium = TextStyle(fontFamily = UiFontFamily, fontSize = 24.sp, lineHeight = 30.sp),
    titleLarge = TextStyle(fontFamily = UiFontFamily, fontSize = 20.sp, lineHeight = 26.sp),
    titleMedium = TextStyle(fontFamily = UiFontFamily, fontSize = 16.sp, lineHeight = 22.sp),
    bodyLarge = TextStyle(fontFamily = UiFontFamily, fontSize = 16.sp, lineHeight = 23.sp),
    bodyMedium = TextStyle(fontFamily = UiFontFamily, fontSize = 14.sp, lineHeight = 20.sp),
    labelLarge = TextStyle(fontFamily = UiFontFamily, fontSize = 14.sp, lineHeight = 18.sp),
    labelMedium = TextStyle(fontFamily = UiFontFamily, fontSize = 12.sp, lineHeight = 16.sp)
)
