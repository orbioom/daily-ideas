package com.orbioom.meeple.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.orbioom.meeple.ui.theme.LocalBrand

/** One bar on a count chart: a label and an integer value. */
data class BarPoint(val label: String, val value: Int)

/**
 * A self-drawn, dependency-free bar chart for monthly play counts. Renders soft rounded bars
 * over a baseline. Handles 0 or 1 points gracefully. Fully described for TalkBack via a single
 * summarizing contentDescription so screen readers get the gist, not every bar.
 */
@Composable
fun PlaysBarChart(
    points: List<BarPoint>,
    barColor: Color,
    modifier: Modifier = Modifier,
    contentDescription: String
) {
    val brand = LocalBrand.current
    if (points.isEmpty()) {
        Box(
            modifier = modifier
                .fillMaxWidth()
                .height(160.dp)
                .clip(RoundedCornerShape(18.dp))
                .background(brand.glass)
                .semantics { this.contentDescription = contentDescription },
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "No plays logged yet to chart.",
                style = MaterialTheme.typography.bodyMedium,
                color = brand.textSecondary
            )
        }
        return
    }

    val maxV = (points.maxOf { it.value }).coerceAtLeast(1)

    Canvas(
        modifier = modifier
            .fillMaxWidth()
            .height(160.dp)
            .clip(RoundedCornerShape(18.dp))
            .background(brand.glass)
            .padding(14.dp)
            .semantics { this.contentDescription = contentDescription }
    ) {
        drawBars(points, maxV, barColor, brand.glassBorder)
    }
}

private fun DrawScope.drawBars(
    points: List<BarPoint>,
    maxV: Int,
    barColor: Color,
    baselineColor: Color
) {
    val w = size.width
    val h = size.height
    val bottomPad = 6f
    val topPad = 6f
    val usableH = (h - topPad - bottomPad).coerceAtLeast(1f)
    val n = points.size
    val slot = w / n
    val barWidth = (slot * 0.55f).coerceAtMost(28f)
    val gap = (slot - barWidth) / 2f

    // Baseline.
    drawLine(
        color = baselineColor,
        start = Offset(0f, h - bottomPad),
        end = Offset(w, h - bottomPad),
        strokeWidth = 1.5f
    )

    points.forEachIndexed { i, p ->
        val norm = p.value.toFloat() / maxV.toFloat()
        val barH = norm * usableH
        val left = i * slot + gap
        val top = (h - bottomPad) - barH
        drawRoundRect(
            color = barColor,
            topLeft = Offset(left, top),
            size = Size(barWidth, barH),
            cornerRadius = androidx.compose.ui.geometry.CornerRadius(4f, 4f)
        )
    }
}
