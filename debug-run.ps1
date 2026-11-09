# Bubbloo Fast Debug & Deploy Script for Flutter + Android
$ErrorActionPreference = "Stop"

# Ensure we are inside the project directory
$projectDir = "c:\Users\anusm\OneDrive\Desktop\projects\ScreenPet"
if (Test-Path $projectDir) {
    Set-Location $projectDir
}

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) {
    Write-Host "[ERROR] adb.exe not found at $adb" -ForegroundColor Red
    exit 1
}

$javaHome = "C:\Program Files\Android\Android Studio\jbr"
if (Test-Path $javaHome) {
    $env:JAVA_HOME = $javaHome
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Bubbloo - Flutter + Native Android Run  " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check connected devices
$devicesOutput = & $adb devices
$lines = $devicesOutput -split "`r?`n" | Where-Object { $_ -match "\tdevice$" }

if ($lines.Count -eq 0) {
    Write-Host ""
    Write-Host "[!] No device detected by ADB yet." -ForegroundColor Yellow
    Write-Host "Make sure on your phone:" -ForegroundColor Yellow
    Write-Host " 1. 'USB debugging' and 'Install via USB' are toggled ON"
    Write-Host " 2. Phone connection mode is set to 'File transfer'"
    Write-Host " 3. You tap 'Allow' on the phone screen popup."
    Write-Host ""
    
    $ip = Read-Host "If connecting wirelessly, enter your phone IP (e.g. 192.168.1.15) or press Enter to retry"
    if ($ip -and $ip.Trim() -ne "") {
        & $adb connect "$($ip.Trim()):5555"
        $devicesOutput = & $adb devices
        $lines = $devicesOutput -split "`r?`n" | Where-Object { $_ -match "\tdevice$" }
    }
}

if ($lines.Count -eq 0) {
    Write-Host "[X] No authorized device found. Please check phone screen and retry." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[OK] Connected device found:" -ForegroundColor Green
$lines | ForEach-Object { Write-Host "  -> $_" -ForegroundColor Green }

Write-Host ""
Write-Host "[1/2] Building Flutter debug APK..." -ForegroundColor Cyan
flutter build apk --debug

Write-Host ""
Write-Host "[2/2] Installing onto phone & launching Bubbloo..." -ForegroundColor Cyan
& $adb install -r "build\app\outputs\flutter-apk\app-debug.apk"
& $adb shell am start -n "com.screenpet.app/.MainActivity"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "   [OK] Bubbloo deployed and launched!    " -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
