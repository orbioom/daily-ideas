# Keep kotlinx.serialization metadata for the serialized domain models.
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.**
-keepclassmembers class com.orbioom.transit.** {
    *** Companion;
}
-keepclasseswithmembers class com.orbioom.transit.** {
    kotlinx.serialization.KSerializer serializer(...);
}
