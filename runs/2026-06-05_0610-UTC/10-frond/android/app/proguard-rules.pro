# Frond — default ProGuard rules. Minification is off for debug/release here,
# but these keep Compose and the model classes safe if it is enabled later.
-keep class com.orbioom.frond.data.** { *; }
-dontwarn org.jetbrains.annotations.**
