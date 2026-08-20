# Tuneit: one-click setup + run on a connected Android phone.
# Everything is logged to setup_log.txt next to this script.

$ErrorActionPreference = 'Continue'
Set-Location -Path $PSScriptRoot
$log = Join-Path $PSScriptRoot 'setup_log.txt'
Start-Transcript -Path $log -Force | Out-Null

function Fail($msg) {
  Write-Host ''
  Write-Host "ОШИБКА: $msg" -ForegroundColor Red
  Stop-Transcript | Out-Null
  Read-Host 'Нажмите Enter, чтобы закрыть'
  exit 1
}

# --- 1. Find Flutter -------------------------------------------------------
$flutter = $null
$cmd = Get-Command flutter -ErrorAction SilentlyContinue
if ($cmd) { $flutter = $cmd.Source }
if (-not $flutter) {
  $candidates = @(
    'F:\src\flutter\bin\flutter.bat',
    'C:\src\flutter\bin\flutter.bat',
    'C:\flutter\bin\flutter.bat',
    'C:\tools\flutter\bin\flutter.bat',
    'C:\dev\flutter\bin\flutter.bat',
    "$env:USERPROFILE\flutter\bin\flutter.bat",
    "$env:USERPROFILE\dev\flutter\bin\flutter.bat",
    "$env:USERPROFILE\src\flutter\bin\flutter.bat",
    "$env:LOCALAPPDATA\flutter\bin\flutter.bat",
    "$env:USERPROFILE\scoop\apps\flutter\current\bin\flutter.bat",
    "$env:USERPROFILE\fvm\default\bin\flutter.bat"
  )
  foreach ($c in $candidates) {
    if (Test-Path $c) { $flutter = $c; break }
  }
}
if (-not $flutter) {
  Fail ("Flutter не найден ни в PATH, ни в типичных папках. " +
    "Установите Flutter (https://docs.flutter.dev/get-started/install/windows), " +
    "либо напишите в чат, где лежит flutter\bin — я поправлю скрипт.")
}
Write-Host "Flutter: $flutter"
& $flutter --version
if ($LASTEXITCODE -ne 0) { Fail 'flutter --version завершился с ошибкой.' }

# --- 2. Generate platform folders -----------------------------------------
if (-not (Test-Path (Join-Path $PSScriptRoot 'android'))) {
  & $flutter create --platforms=android,ios --org kz.tuneit --project-name app .
  if ($LASTEXITCODE -ne 0) { Fail 'flutter create не удался.' }
} else {
  Write-Host 'android/ уже существует — flutter create пропущен.'
}

# --- 3. Patch manifests (no Python needed) ---------------------------------
$manifest = Join-Path $PSScriptRoot 'android\app\src\main\AndroidManifest.xml'
if (Test-Path $manifest) {
  $t = Get-Content -Raw -Encoding UTF8 $manifest
  if ($t -notmatch 'RECORD_AUDIO') {
    $i = $t.IndexOf('>', $t.IndexOf('<manifest')) + 1
    $perm = "`r`n    <uses-permission android:name=`"android.permission.RECORD_AUDIO`"/>"
    $t = $t.Insert($i, $perm)
    Set-Content -Path $manifest -Value $t -Encoding UTF8 -NoNewline
    Write-Host 'android: добавлено RECORD_AUDIO'
  } else {
    Write-Host 'android: RECORD_AUDIO уже на месте'
  }
}
$plist = Join-Path $PSScriptRoot 'ios\Runner\Info.plist'
if (Test-Path $plist) {
  $t = Get-Content -Raw -Encoding UTF8 $plist
  if ($t -notmatch 'NSMicrophoneUsageDescription') {
    $usage = 'Микрофон нужен, чтобы слышать звук струны и показывать точность настройки. Запись никуда не отправляется. / The microphone is used to hear the string and show tuning accuracy. Audio is never sent anywhere.'
    $entry = "`r`n`t<key>NSMicrophoneUsageDescription</key>`r`n`t<string>$usage</string>"
    $i = $t.IndexOf('<dict>') + '<dict>'.Length
    $t = $t.Insert($i, $entry)
    Set-Content -Path $plist -Value $t -Encoding UTF8 -NoNewline
    Write-Host 'ios: добавлено NSMicrophoneUsageDescription'
  }
}

# --- 4. Packages, analyze, tests -------------------------------------------
& $flutter pub get
if ($LASTEXITCODE -ne 0) { Fail 'flutter pub get не удался (нужен интернет при первом запуске).' }

& $flutter analyze
$analyzeCode = $LASTEXITCODE

& $flutter test
$testCode = $LASTEXITCODE

if ($analyzeCode -ne 0 -or $testCode -ne 0) {
  Write-Host ''
  Write-Host 'analyze или тесты нашли проблемы — лог сохранён в setup_log.txt.' -ForegroundColor Yellow
  Write-Host 'Напишите в чат Claude «готово» — он прочитает лог и исправит код.' -ForegroundColor Yellow
  Stop-Transcript | Out-Null
  Read-Host 'Нажмите Enter, чтобы закрыть'
  exit 1
}

# --- 5. Run on a connected Android phone -----------------------------------
Write-Host ''
Write-Host 'Ищу подключённый Android-телефон...'
$devicesJson = & $flutter devices --machine | Out-String
$androidId = $null
try {
  $devices = $devicesJson | ConvertFrom-Json
  foreach ($d in $devices) {
    if ($d.targetPlatform -like 'android*') { $androidId = $d.id; break }
  }
} catch { }

if ($androidId) {
  Write-Host "Устройство найдено: $androidId. Собираю и запускаю (release)..."
  Stop-Transcript | Out-Null
  & $flutter run --release -d $androidId
  Read-Host 'Нажмите Enter, чтобы закрыть'
} else {
  Write-Host ''
  Write-Host 'Android-телефон не найден.' -ForegroundColor Yellow
  Write-Host 'Проверьте: 1) телефон подключён по USB; 2) на телефоне включена'
  Write-Host 'отладка по USB (Настройки -> Для разработчиков); 3) на экране'
  Write-Host 'телефона подтверждён запрос «Разрешить отладку с этого компьютера».'
  Write-Host 'Затем запустите setup.bat ещё раз — всё уже собрано, будет быстро.'
  Stop-Transcript | Out-Null
  Read-Host 'Нажмите Enter, чтобы закрыть'
}
