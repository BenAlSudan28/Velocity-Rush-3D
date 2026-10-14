# Android export notes

The repository intentionally does not include Godot's large Android export templates, SDK, NDK or a signing keystore. The GitHub Actions workflow downloads the Godot 4.4.1 editor plus matching official export templates and configures the Android SDK for each build.

The Android preset is named exactly `Android`, targets Android 9 / API 28 or later, and exports a debug APK signed with the standard debug signing workflow. It is intended for device testing, not Play Store production release. To publish later, use your own secure release keystore and keep its credentials in GitHub Actions secrets; never commit a keystore/password into this repository.
