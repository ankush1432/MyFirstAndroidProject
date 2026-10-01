####################################
# Flutter
####################################
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

####################################
# Google Play Core (Split Install)
####################################
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

####################################
# Firebase
####################################
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

####################################
# Google Sign-In / Play Services
####################################
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

####################################
# Facebook Ads
####################################
-keep class com.facebook.** { *; }
-dontwarn com.facebook.**

####################################
# Kotlin
####################################
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

####################################
# Annotations
####################################
-keep class com.facebook.infer.annotation.** { *; }
-dontwarn com.facebook.infer.annotation.**
