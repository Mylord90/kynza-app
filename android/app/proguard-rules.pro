# KYNZA release R8 rules (Phase 10, Enterprise Hardening pass).
# Flutter's own engine/embedding classes ship their own consumer ProGuard
# rules bundled in the flutter_embedding AAR — not duplicated here.

# Play Core (Flutter's embedding references these for deferred-component /
# Play Store split-install support, which this app doesn't use) — without
# this, R8 warns about missing classes and can fail the build outright on
# some AGP versions.
-dontwarn com.google.android.play.core.**

# Firebase Crashlytics — keep enough attributes for de-obfuscated stack
# traces to actually be attributable (Crashlytics itself re-symbolicates
# using the uploaded mapping file, but the attributes below must survive
# shrinking for that mapping to line up).
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
