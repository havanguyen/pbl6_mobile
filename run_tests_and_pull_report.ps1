$packageName = "com.example.pbl6mobile"
$remoteDir = "/storage/emulated/0/Download/test_result"
$localDir = ".\bao_cao_test"
$testSuite = "integration_test/tests/run_all_tests.dart"

Write-Host "Preparing for E2E Test Suite..." -ForegroundColor Cyan

Write-Host "Cleaning App Data..." -ForegroundColor Yellow
adb shell pm clear $packageName | Out-Null
adb shell pm grant $packageName android.permission.WRITE_EXTERNAL_STORAGE | Out-Null
adb shell pm grant $packageName android.permission.READ_EXTERNAL_STORAGE | Out-Null

Write-Host "Building and Running All Tests..." -ForegroundColor Cyan
flutter test $testSuite

Write-Host "All tests finished. Pulling reports..." -ForegroundColor Cyan

if (-not (Test-Path $localDir)) {
    New-Item -ItemType Directory -Path $localDir | Out-Null
}
adb pull "$remoteDir/." "$localDir"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Reports saved to $localDir" -ForegroundColor Green
    Invoke-Item $localDir
} else {
    Write-Host "Failed to pull reports." -ForegroundColor Red
}