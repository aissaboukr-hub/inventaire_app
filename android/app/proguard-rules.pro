# android/app/proguard-rules.pro

# Keep Flutter Driver used by integration tests.
-keep class io.flutter.embedding.engine.FlutterEngine { *; }

# Keep common plugins
-keep class io.flutter.plugins.** { *; }

# SQLite
-keep class org.sqlite.** { *; }

# Excel
-keep class org.apache.poi.** { *; }

# Camera/ML Kit
-keep class com.google.mlkit.** { *; }
-keep class androidx.camera.** { *; }

# General Android
-dontwarn android.**
-dontwarn com.android.**
