# App Icon Setup Instructions

## 📱 How to Add Your App Icon

1. **Create your app icon image:**

   - Size: 1024x1024 pixels (minimum)
   - Format: PNG with transparency support
   - Name: `app_icon.png`
   - Place it in this folder: `assets/icons/app_icon.png`

2. **Design suggestions for Booking Tracker:**

   - 🏨 Hotel building with calendar
   - 📅 Calendar with bed icon
   - 🛏️ Bed with checkmark
   - 📋 Clipboard with hotel
   - Use your app's blue theme: #007AFF

3. **Generate icons for all platforms:**

   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

4. **Rebuild your app:**
   ```bash
   flutter clean
   flutter build apk --debug
   ```

## 🎨 Icon Requirements

- **Android**: Various sizes from 48x48 to 192x192
- **iOS**: Various sizes from 20x20 to 1024x1024
- **Web**: 192x192 and 512x512
- **Windows**: 48x48 to 256x256

The flutter_launcher_icons plugin will automatically generate all required sizes from your 1024x1024 source image.

## 📂 Current Status

- ✅ Assets folder created
- ✅ pubspec.yaml configured
- ⏳ Waiting for app_icon.png file
- ⏳ Icon generation pending
