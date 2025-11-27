# Flutter Local Notifications
-keep class com.dexterous.** { *; }
-keep class androidx.core.app.** { *; }

# AndroidX
-keep class androidx.** { *; }
-dontwarn androidx.**

# Gson (flutter_local_notificationsが使用)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# 通知関連のクラスを保持
-keep class * extends android.app.Service
-keep class * extends android.content.BroadcastReceiver