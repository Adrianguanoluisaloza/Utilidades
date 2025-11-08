# ========================================
# REGLAS PROGUARD/R8 PARA FLUTTER + GOOGLE MAPS
# ========================================

# ✅ Mantener Flutter Engine
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# ✅ Google Maps Flutter
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }
-dontwarn com.google.android.gms.**

# ✅ Google Play Services (Location, Maps)
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ✅ Google Play Core (para Flutter deferred components y dynamic features)
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# ✅ Mantener clases de Google Maps específicas
-keep public class com.google.android.gms.maps.GoogleMap { *; }
-keep public class com.google.android.gms.maps.model.** { *; }
-keep public class com.google.android.gms.location.** { *; }

# ✅ Location plugin
-keep class io.flutter.plugins.location.** { *; }

# ✅ Geolocator plugin
-keep class com.baseflow.geolocator.** { *; }

# ✅ Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# ✅ Mantener anotaciones
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# ✅ Mantener nombres de clases y métodos para debugging
-keepattributes SourceFile,LineNumberTable

# ✅ HTTP y networking
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ✅ Dart/JSON serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt
-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# ✅ Optimizaciones generales
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# ✅ Remover logs en producción (opcional, descomenta si quieres)
# -assumenosideeffects class android.util.Log {
#     public static *** d(...);
#     public static *** v(...);
#     public static *** i(...);
# }
