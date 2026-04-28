# Keep notification classes
-keep class com.dexterous.** { *; }
-keep class androidx.core.app.NotificationCompat { *; }
-keep class androidx.core.app.NotificationCompat$* { *; }

# Keep Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Keep timezone data
-keep class net.danlew.android.joda.** { *; }
-dontwarn net.danlew.android.joda.**

# Keep work manager
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# Keep notification receiver classes
-keepclassmembers class * extends android.content.BroadcastReceiver {
    <init>(...);
}
