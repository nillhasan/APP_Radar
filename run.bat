@echo off
echo ========================================================
echo Starting AppRadar Flutter Web on http://localhost:3000
echo ========================================================
cd /d "%~dp0flutter_app"
flutter run -d chrome --web-port 3000 %*
