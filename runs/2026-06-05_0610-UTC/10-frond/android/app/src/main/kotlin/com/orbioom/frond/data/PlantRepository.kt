package com.orbioom.frond.data

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * Local-first persistence: the whole garden is stored as a JSON string in
 * SharedPreferences. No database, no annotation processors, no network.
 */
class PlantRepository(context: Context) {

    private val prefs = context.getSharedPreferences("frond.store", Context.MODE_PRIVATE)

    fun load(): List<Plant> {
        val raw = prefs.getString(KEY, null) ?: return emptyList()
        return runCatching {
            val arr = JSONArray(raw)
            (0 until arr.length()).map { i ->
                val o = arr.getJSONObject(i)
                Plant(
                    id = o.getString("id"),
                    name = o.getString("name"),
                    species = o.optString("species", ""),
                    intervalDays = o.getInt("intervalDays"),
                    lastWatered = o.getLong("lastWatered")
                )
            }
        }.getOrDefault(emptyList())
    }

    fun save(plants: List<Plant>) {
        val arr = JSONArray()
        plants.forEach { p ->
            arr.put(
                JSONObject()
                    .put("id", p.id)
                    .put("name", p.name)
                    .put("species", p.species)
                    .put("intervalDays", p.intervalDays)
                    .put("lastWatered", p.lastWatered)
            )
        }
        prefs.edit().putString(KEY, arr.toString()).apply()
    }

    fun hasData(): Boolean = prefs.contains(KEY)

    companion object { private const val KEY = "plants" }
}
