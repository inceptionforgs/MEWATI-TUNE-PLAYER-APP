# ============================================================
# Mewati Tune Player — R8/ProGuard keep rules
# Referenced from android/app/build.gradle's release buildType.
# Without these, R8 strips reflection-based / plugin-registered
# classes from just_audio, audio_service, supabase_flutter, and
# background_downloader, breaking the release build silently
# (works in debug, crashes or no-ops in release).
# ============================================================

# ---- just_audio ----
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# ---- audio_service (background audio / media notification) ----
-keep class com.ryanheise.audioservice.** { *; }
-keep class android.support.v4.media.** { *; }
-keep class androidx.media.** { *; }
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# ---- supabase_flutter and its transitive Dart/Kotlin deps ----
# (gotrue, postgrest, realtime, storage clients use reflection/JSON
# (de)serialization internally — keep model & client classes intact)
-keep class io.supabase.** { *; }
-keep class com.supabase.** { *; }
-keep class io.github.jan.supabase.** { *; }
-dontwarn io.github.jan.supabase.**

# WebSocket / Ktor / OkHttp used transitively by supabase_flutter's
# realtime client — these rely on reflection for platform selection.
-keep class io.ktor.** { *; }
-dontwarn io.ktor.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# JSON serialization (kotlinx.serialization) used by supabase_flutter
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt
-keep,includedescriptorclasses class com.mewatitune.player.**$$serializer { *; }
-keepclassmembers class com.mewatitune.player.** {
    *** Companion;
}
-keepclasseswithmembers class com.mewatitune.player.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# ---- background_downloader ----
-keep class com.bbflight.background_downloader.** { *; }
-dontwarn com.bbflight.background_downloader.**

# ---- General Flutter plugin safety net ----
# Keep plugin registrant / embedding classes so platform channel
# method names survive obfuscation.
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keepclassmembers class * {
    @io.flutter.plugin.common.PluginRegistry$Registrar *;
}

# ---- Play Core split-install (deferred components) ----
# Referenced by Flutter's embedding for Play Store dynamic feature
# delivery, but this app does not use split/deferred components —
# these classes are intentionally absent, safe to ignore.
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
