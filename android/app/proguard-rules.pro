# Keep Flutter entry points and plugin registrants.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Firebase and Google Play Services classes used by reflection.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Kotlin metadata used at runtime by some libraries.
-keep class kotlin.Metadata { *; }
