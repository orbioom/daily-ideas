package com.orbioom.forage.domain

import kotlinx.serialization.Serializable
import java.util.Locale

/** Pure Kotlin domain models — no Android imports. Serialized to JSON on disk. */

@Serializable
data class Ingredient(
    val name: String,
    val quantity: Double = 0.0,
    val unit: String = ""
)

@Serializable
enum class RecipeCategory(val title: String) {
    BREAKFAST("Breakfast"),
    MAIN("Main"),
    SIDE("Side"),
    DESSERT("Dessert"),
    DRINK("Drink"),
    SNACK("Snack");

    companion object {
        fun fromTitleOrDefault(raw: String): RecipeCategory =
            entries.firstOrNull { it.title.equals(raw, ignoreCase = true) } ?: MAIN
    }
}

@Serializable
data class Recipe(
    val id: String,
    val title: String,
    val description: String = "",
    val category: RecipeCategory = RecipeCategory.MAIN,
    val servings: Int = 2,
    val prepMinutes: Int = 0,
    val cookMinutes: Int = 0,
    val ingredients: List<Ingredient> = emptyList(),
    val steps: List<String> = emptyList(),
    val tags: List<String> = emptyList(),
    val favorite: Boolean = false,
    val createdAt: Long = 0L
) {
    val totalMinutes: Int get() = prepMinutes + cookMinutes
}

enum class SortOrder(val title: String) {
    RECENT("Recently added"),
    TITLE("Title A–Z"),
    TIME("Quickest first"),
    CATEGORY("Category");
}

/**
 * Scale a recipe's ingredient quantities to a new serving count. This is the heart of
 * the recipe box: quantities scale by the ratio, and amounts are formatted into clean,
 * cook-friendly strings (whole numbers, common fractions, or one decimal).
 */
object RecipeScaler {

    /** Returns ingredients with quantities scaled from [baseServings] to [targetServings]. */
    fun scaledIngredients(recipe: Recipe, targetServings: Int): List<ScaledIngredient> {
        val base = recipe.servings.coerceAtLeast(1)
        val target = targetServings.coerceIn(1, 99)
        val factor = target.toDouble() / base.toDouble()
        return recipe.ingredients.map { ing ->
            val scaled = ing.quantity * factor
            ScaledIngredient(
                name = ing.name,
                amount = if (ing.quantity > 0.0) formatAmount(scaled) else "",
                unit = ing.unit
            )
        }
    }

    data class ScaledIngredient(val name: String, val amount: String, val unit: String) {
        /** A single display line: "1 ½ cups flour". */
        val line: String
            get() = listOf(amount, unit, name)
                .filter { it.isNotBlank() }
                .joinToString(" ")
    }

    /** Format a quantity into a friendly cooking amount using nearby simple fractions. */
    fun formatAmount(value: Double): String {
        if (value <= 0.0) return ""
        val whole = value.toLong()
        val frac = value - whole

        val fractionGlyph = nearestFraction(frac)
        return when {
            fractionGlyph == null && whole == 0L -> "0"
            fractionGlyph == null -> whole.toString()
            whole == 0L -> fractionGlyph
            else -> "$whole$fractionGlyph"
        }.let { result ->
            // Fall back to one decimal when no clean fraction fits and there is a remainder.
            if (fractionGlyph == null && frac > 0.0001) {
                String.format(Locale.US, "%.1f", value)
            } else result
        }
    }

    private val fractions = listOf(
        0.125 to "⅛", 0.25 to "¼", 0.333 to "⅓", 0.5 to "½",
        0.667 to "⅔", 0.75 to "¾"
    )

    /** Snap a fractional part to the nearest common cooking fraction within tolerance. */
    private fun nearestFraction(frac: Double): String? {
        if (frac < 0.0625) return null
        var best: Pair<Double, String>? = null
        var bestDelta = Double.MAX_VALUE
        for (candidate in fractions) {
            val delta = kotlin.math.abs(frac - candidate.first)
            if (delta < bestDelta) { bestDelta = delta; best = candidate }
        }
        return if (bestDelta <= 0.06) best?.second else null
    }
}
