# flutter_local_notifications: rejalashtirilgan bildirishnomalar GSON orqali
# seriyalashtiriladi. R8 generic signaturalarni o'chirsa, jiringlash vaqtida
# ScheduledNotificationReceiver "Missing type parameter" bilan crash bo'ladi.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type

# flutter_callkit_incoming ham GSON ishlatadi
-keep class com.hiennv.flutter_callkit_incoming.** { *; }
