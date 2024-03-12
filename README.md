# Mobile Computing Project

Mobile Computing University Course Project.

This is a cross-platform Flutter project but only the Android side has been implemented.

## Requirements
- Flutter 3.19
- JDK 17
- Gradle wrapper has been updated to 8.6 with `./gradlew wrapper --gradle-version latest`

## Generate models
If models have changed, run:
```sh
dart run build_runner build
```

## Secure API keys
See 
* [Restricting API keys](https://developers.google.com/maps/documentation/android-sdk/get-api-key#restrict_key)
* [API security best practices](https://developers.google.com/maps/api-security-best-practices)

Find your SHA-1 fingerprint with e.g.
```sh
keytool -list -v -keystore "C:\Users\Janne\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```