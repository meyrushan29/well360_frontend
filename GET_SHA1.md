# How to Get SHA-1 Certificate for Google Sign-In

## Method 1: Using Android Studio (Easiest)
1. Open Android Studio
2. Open this project's `android` folder
3. Click on **Gradle** tab (right side)
4. Navigate to: `app > Tasks > android > signingReport`
5. Double-click `signingReport`
6. Look for `SHA1` in the output window
7. Copy the SHA1 value

## Method 2: Using Command Line
Run this command in PowerShell:

```powershell
cd "C:\Users\YOUR_USERNAME\.android"
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Replace `YOUR_USERNAME` with your Windows username.

Look for the line that says:
```
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

## Method 3: Create Debug Keystore (if it doesn't exist)
```powershell
keytool -genkey -v -keystore C:\Users\YOUR_USERNAME\.android\debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000
```

Then use Method 2 to get the SHA1.

## What to Do With SHA-1

### For Google Cloud Console:
1. Go to: https://console.cloud.google.com/
2. Navigate to: **APIs & Services > Credentials**
3. Click: **Create Credentials > OAuth client ID**
4. Select: **Android**
5. Enter:
   - **Package name**: `com.example.flutter_application_1`
   - **SHA-1 certificate fingerprint**: [Paste the SHA1 you copied]
6. Click **Create**
7. Download `google-services.json`
8. Place it in: `android/app/google-services.json`

## Package Name Location
Your package name is defined in:
`android/app/build.gradle.kts` -> Line 25:
```kotlin
applicationId = "com.example.flutter_application_1"
```

You can also find it in:
`android/app/src/main/AndroidManifest.xml` -> `package` attribute
