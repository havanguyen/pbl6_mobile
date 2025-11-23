# Script to run integration tests and pull Excel reports from Android device

$packageName = "com.example.pbl6mobile"
# The path where the app saves the file (Public Download Dir)
$remoteDir = "/storage/emulated/0/Download/test_result"
$localDir = ".\bao_cao_test"

# Create local directory if it doesn't exist
if (-not (Test-Path -Path $localDir)) {
    New-Item -ItemType Directory -Path $localDir | Out-Null
    Write-Host "Created local directory: $localDir" -ForegroundColor Green
}

# 1. Build the APK first to ensure we can install it
Write-Host "Building APK..." -ForegroundColor Cyan
flutter build apk --debug

# 2. Install the APK
Write-Host "Installing APK..." -ForegroundColor Cyan
$apkPath = "build\app\outputs\flutter-apk\app-debug.apk"
if (Test-Path $apkPath) {
    adb install -r $apkPath
} else {
    Write-Host "APK not found at $apkPath. Build failed?" -ForegroundColor Red
    exit 1
}

# 3. Grant permissions to ensure app can write to Download folder
Write-Host "Granting storage permissions..." -ForegroundColor Cyan
adb shell pm grant $packageName android.permission.WRITE_EXTERNAL_STORAGE
adb shell pm grant $packageName android.permission.READ_EXTERNAL_STORAGE

# Function to run a test file
function Run-Test {
    param (
        [string]$testFile
    )
    Write-Host "Running test: $testFile" -ForegroundColor Cyan
    # flutter test will re-install, but usually keeps permissions if signed same way
    # We use --use-application-binary to skip rebuild/install if possible? 
    # No, integration_test usually wants to build. 
    # But since we just built, it should be fast.
    flutter test integration_test/tests/$testFile
}

# Run all tests
Run-Test "e2e_login_test.dart"
Run-Test "e2e_admin_flow_test.dart"
Run-Test "e2e_location_work_test.dart"

Write-Host "All tests completed." -ForegroundColor Green

# Pull reports
Write-Host "Pulling reports from device..." -ForegroundColor Cyan

# Pull the entire directory content
adb pull "$remoteDir/." "$localDir"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Reports successfully pulled to $localDir" -ForegroundColor Green
    Invoke-Item $localDir
} else {
    Write-Host "Failed to pull reports. Make sure the device is connected and the path is correct." -ForegroundColor Red
    Write-Host "Remote Path: $remoteDir"
}
