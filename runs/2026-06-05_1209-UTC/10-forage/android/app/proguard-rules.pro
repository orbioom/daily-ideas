# Keep kotlinx.serialization metadata for the serialized domain models.
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.**
-keepclassmembers class com.orbioom.forage.** {
    *** Companion;
}
-keepclasseswithmembers class com.orbioom.forage.** {
    kotlinx.serialization.KSerializer serializer(...);
}
