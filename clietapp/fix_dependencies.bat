@echo off
echo 🔄 Resolving Flutter dependency lock issue...

echo 🛑 Stopping all Dart processes...
taskkill /F /IM dart.exe /T 2>nul || echo No dart processes found

echo 🛑 Stopping all Flutter processes...
taskkill /F /IM flutter.exe /T 2>nul || echo No flutter processes found

echo 🧹 Cleaning project...
flutter clean

echo 📦 Removing pub cache locks...
del /Q "%LOCALAPPDATA%\Pub\Cache\*.lock" 2>nul || echo No lock files found

echo 🔄 Attempting to get dependencies...
flutter pub get

echo ✅ Dependency resolution complete!
pause
