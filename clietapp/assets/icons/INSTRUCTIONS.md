# Temporary App Icon

Since we need an actual PNG file for testing, here are your options:

## 🚀 **Quick Solution:**

1. **Download any 1024x1024 PNG image** from the internet
2. **Rename it to `app_icon.png`**
3. **Place it in this folder** (`assets/icons/app_icon.png`)

## 📱 **Or use this simple approach:**

1. Open MS Paint or any image editor
2. Create a 1024x1024 image
3. Fill with blue background (#007AFF)
4. Add white text "BT" (Booking Tracker)
5. Save as `app_icon.png` in this folder

## 🔄 **Then run the generation command:**

```bash
flutter pub run flutter_launcher_icons
```

## 📋 **What this will generate:**

- **Android**: Various sized icons in `android/app/src/main/res/mipmap-*`
- **iOS**: Icons in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- **Web**: Favicon and web app icons
- **Windows**: Windows app icon

Once you have a proper app icon design, just replace `app_icon.png` and run the command again!
