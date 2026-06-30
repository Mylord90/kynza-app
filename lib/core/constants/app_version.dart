import 'dart:io';

// Must match pubspec.yaml `version: <name>+<code>`.
// Update both here and pubspec.yaml before each release.
const kAppVersionCode = 1;
const kAppVersionName = '1.0.0';

String get kAppPlatform => Platform.isAndroid ? 'android' : 'ios';

// Store URLs (update before first Play Store / App Store submission)
const kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.kynza.app';
const kAppStoreUrl =
    'https://apps.apple.com/app/kynza/id000000000'; // placeholder