# ============================================================================
# ProGuard / R8 rules for ZapfNavi
# ============================================================================

# Flutter-specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase Crashlytics
-keep class com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Supabase / GoTrue Auth (keeps JSON models used via reflection)
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Geolocator
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# WorkManager
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# Flutter Local Notifications
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# AndroidX
-keep class androidx.** { *; }
-dontwarn androidx.**

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# Keep annotations
-keepattributes *Annotation*,EnclosingMethod,InnerClasses

# Connectivity Plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }
-dontwarn dev.fluttercommunity.plus.connectivity.**

# Prevent R8 from removing classes used by Flutter plugins via JNI
-keep class * extends io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
