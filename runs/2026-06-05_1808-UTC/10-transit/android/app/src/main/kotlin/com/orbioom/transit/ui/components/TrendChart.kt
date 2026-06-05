package com.orbioom.transit.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.background
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.orbioom.transit.ui.theme.LocalBrand

/** One point on a trend line: an x position 0..1 across time and a raw value. */
data class TrendPoint(val x: Float, val value: Float, val label: String)

/**
 * A self-drawn, dependency-free trend chart. Renders a line (with a soft gradient fill),
 * value dots, and a baseline. Handles 0 or 1 points gracefully. Fully described for TalkBack
 * via a single summarizing contentDescription so screen readers get the gist, not 12 dots.
 */
@Composable
fun TrendChart(
    points: List<TrendPoint>,
    lineColor: Color,
    modifier: Modifier = Modifier,
    contentDescription: String
) {
    val brand = LocalBrand.current
    if (points.size < 2) {
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
                text = "Not enough data yet to chart a trend.",
                style = MaterialTheme.typography.bodyMedium,
                color = brand.textSecondary
            )
        }
        return
    }

    val minV = points.minOf { it.value }
    val maxV = points.maxOf { it.value }
    val range = (maxV - minV).takeIf { it > 0.0001f } ?: 1f

    Canvas(
        modifier = modifier
            .fillMaxWidth()
            .height(160.dp)
            .clip(RoundedCornerShape(18.dp))
            .background(brand.glass)
            .padding(14.dp)
            .semantics { this.contentDescription = contentDescription }
    ) {
        drawTrend(points, minV, range, lineColor, brand.glassBorder)
    }
}

private fun DrawScope.drawTrend(
    points: List<TrendPoint>,
    minV: Float,
    range: Float,
    lineColor: Color,
    baselineColor: Color
) {
    val w = size.width
    val h = size.height
    val topPad = 6f
    val bottomPad = 6f
    val usableH = (h - topPad - bottomPad).coerceAtLeast(1f)

    fun px(p: TrendPoint) = p.x * w
    fun py(p: TrendPoint): Float {
        val norm = (p.value - minV) / range
        return topPad + (1f - norm) * usableH
    }

    // Baseline.
    drawLine(
        color = baselineColor,
        start = Offset(0f, h - bottomPad),
        end = Offset(w, h - bottomPad),
        strokeWidth = 1.5f
    )

    // Gradient fill under the line.
    val fillPath = Path().apply {
        moveTo(px(points.first()), h - bottomPad)
        points.forEach { lineTo(px(it), py(it)) }
        lineTo(px(points.last()), h - bottomPad)
        close()
    }
    drawPath(
        path = fillPath,
        brush = Brush.verticalGradient(
            colors = listOf(lineColor.copy(alpha = 0.22f), lineColor.copy(alpha = 0.0f))
        )
    )

    // The line itself.
    val linePath = Path().apply {
        points.forEachIndexed { i, p ->
            if (i == 0) moveTo(px(p), py(p)) else lineTo(px(p), py(p))
        }
    }
    drawPath(
        path = linePath,
        color = lineColor,
        style = Stroke(width = 3.5f)
    )

    // Dots at each reading.
    points.forEach { p ->
        drawCircle(color = lineColor, radius = 4.5f, center = Offset(px(p), py(p)))
        drawCircle(color = Color.White, radius = 2f, center = Offset(px(p), py(p)))
    }
}

/** A small color-keyed legend chip for the chart. */
@Composable
fun ChartLegend(items: List<Pair<String, Color>>, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier.clearAndSetSemantics { },
        horizontalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        items.forEach { (label, color) ->
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(10.dp)
                        .clip(RoundedCornerShape(50))
                        .background(color)
                        .padding(end = 6.dp)
                )
                Column(modifier = Modifier.padding(start = 6.dp)) {
                    Text(
                        text = label,
                        style = MaterialTheme.typography.labelMedium,
                        color = LocalBrand.current.textSecondary,
                        fontWeight = FontWeight.Medium
                    )
                }
            }
        }
    }
}
