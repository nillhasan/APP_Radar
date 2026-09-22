Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Starting AppRadar Flutter Web on http://localhost:3000" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan
Set-Location "$PSScriptRoot\flutter_app"
flutter run -d chrome --web-port 3000 $args
