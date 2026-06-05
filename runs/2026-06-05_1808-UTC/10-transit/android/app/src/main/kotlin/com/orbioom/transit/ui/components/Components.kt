package com.orbioom.transit.ui.components

import android.provider.Settings
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.orbioom.transit.ui.theme.LocalBrand

/** Brand motion easing — calm, decisive, never bouncy. */
val TransitEasing = CubicBezierEasing(0.16f, 1f, 0.3f, 1f)

/**
 * Honour the system "remove animations" / animator-duration-scale setting. When the user has
 * disabled animations we degrade tasteful motion to instant rather than ignoring their choice.
 */
@Composable
fun rememberMotionEnabled(): Boolean {
    val context = LocalContext.current
    return remember {
        val scale = runCatching {
            Settings.Global.getFloat(
                context.contentResolver,
                Settings.Global.ANIMATOR_DURATION_SCALE,
                1f
            )
        }.getOrDefault(1f)
        scale != 0f
    }
}

/** A tween that collapses to instant when the user has disabled animations. */
@Composable
fun <T> motionTween(durationMillis: Int = 320) =
    tween<T>(durationMillis = if (rememberMotionEnabled()) durationMillis else 0, easing = TransitEasing)

/** Layered mist page background — never pure white. */
@Composable
fun MistBackground(content: @Composable () -> Unit) {
    val brand = LocalBrand.current
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Brush.verticalGradient(listOf(brand.mistTop, brand.mistBottom)))
    ) { content() }
}

/** A Liquid Glass panel — translucent surface, hairline luminous border. */
@Composable
fun GlassCard(
    modifier: Modifier = Modifier,
    contentPadding: PaddingValues = PaddingValues(16.dp),
    onClick: (() -> Unit)? = null,
    onClickLabel: String? = null,
    content: @Composable () -> Unit
) {
    val brand = LocalBrand.current
    val shape = RoundedCornerShape(18.dp)
    val inner = Modifier
        .clip(shape)
        .background(brand.glass)
        .let { base ->
            if (onClick != null) {
                base.clickable(role = Role.Button, onClickLabel = onClickLabel, onClick = onClick)
            } else base
        }
        .padding(contentPadding)

    Surface(
        modifier = modifier,
        shape = shape,
        color = Color.Transparent,
        border = BorderStroke(1.dp, brand.glassBorder)
    ) {
        Box(inner) { content() }
    }
}

/** The single focal ink action: ink gradient, white label, 12dp radius, ≥48dp tall. */
@Composable
fun InkButton(
    text: String,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    enabled: Boolean = true,
    onClick: () -> Unit
) {
    val brand = LocalBrand.current
    val shape = RoundedCornerShape(12.dp)
    val fill = if (enabled) brand.inkGradient
    else Brush.verticalGradient(listOf(Color.Gray.copy(alpha = 0.5f), Color.Gray.copy(alpha = 0.5f)))

    Box(
        modifier = modifier
            .heightIn(min = 52.dp)
            .clip(shape)
            .background(fill)
            .clickable(enabled = enabled, role = Role.Button, onClick = onClick)
            .padding(horizontal = 20.dp, vertical = 14.dp),
        contentAlignment = Alignment.Center
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (icon != null) {
                Icon(icon, contentDescription = null, tint = Color.White, modifier = Modifier.size(20.dp))
            }
            Text(
                text = text,
                color = Color.White,
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.SemiBold
            )
        }
    }
}

/** A live status dot — restrained green, used only for active/success signals. */
@Composable
fun LiveDot(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .size(8.dp)
            .clip(RoundedCornerShape(50))
            .background(LocalBrand.current.live)
    )
}

@Composable
fun SecondaryText(text: String, modifier: Modifier = Modifier) {
    Text(
        text = text,
        color = LocalBrand.current.textSecondary,
        style = MaterialTheme.typography.bodyMedium,
        modifier = modifier
    )
}

/** A label + value stat tile used across detail and insights. */
@Composable
fun StatTile(
    label: String,
    value: String,
    modifier: Modifier = Modifier,
    accent: Boolean = false
) {
    val brand = LocalBrand.current
    GlassCard(modifier = modifier, contentPadding = PaddingValues(14.dp)) {
        Column {
            Text(
                text = label.uppercase(),
                style = MaterialTheme.typography.labelMedium,
                color = brand.textTertiary,
                fontWeight = FontWeight.SemiBold
            )
            Text(
                text = value,
                style = MaterialTheme.typography.titleLarge,
                color = if (accent) brand.live else MaterialTheme.colorScheme.onBackground,
                fontWeight = FontWeight.Bold
            )
        }
    }
}
