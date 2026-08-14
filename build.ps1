#Requires -Version 5.1
<#
.SYNOPSIS
  Build a Windows x64 installer for OneXray.

.DESCRIPTION
  Compiles the Flutter Windows x64 Release bundle and packages it with Inno Setup.
  The installer is written to dist\oneXray-setup-v<marketing-version>.exe
  (version comes from pubspec.yaml, for example 26.8.3+1 -> v26.8.3).

.PARAMETER SkipFlutterBuild
  Skip `flutter build windows` and package the existing Release directory.

.PARAMETER FlutterRoot
  Flutter SDK root. Defaults to $env:FLUTTER_ROOT, then D:\flutter\stable, then PATH.

.PARAMETER Version
  Override the marketing version used in the installer file name.
#>
[CmdletBinding()]
param(
    [switch] $SkipFlutterBuild,
    [string] $FlutterRoot,
    [string] $Version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = $PSScriptRoot
if (-not $RepoRoot) {
    $RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$ReleaseDir = Join-Path $RepoRoot "build\windows\x64\runner\Release"
$DistDir = Join-Path $RepoRoot "dist"
$AppDir = Join-Path $RepoRoot "windows\app"
$IconFile = Join-Path $RepoRoot "windows\runner\resources\app_icon.ico"
$PubspecFile = Join-Path $RepoRoot "pubspec.yaml"
$IsccCandidates = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
)

function Write-Step([string] $Message) {
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Get-MarketingVersion {
    if ($Version) {
        return $Version.TrimStart("v", "V")
    }
    if (-not (Test-Path $PubspecFile)) {
        throw "pubspec.yaml not found: $PubspecFile"
    }
    $line = Select-String -Path $PubspecFile -Pattern '^\s*version:\s*(\S+)' |
        Select-Object -First 1
    if (-not $line) {
        throw "Could not read version from pubspec.yaml"
    }
    $raw = $line.Matches[0].Groups[1].Value
    return ($raw -split "\+", 2)[0]
}

function Resolve-FlutterBat {
    $roots = @()
    if ($FlutterRoot) { $roots += $FlutterRoot }
    if ($env:FLUTTER_ROOT) { $roots += $env:FLUTTER_ROOT }
    $roots += "D:\flutter\stable"

    foreach ($root in $roots) {
        $bat = Join-Path $root "bin\flutter.bat"
        if (Test-Path $bat) {
            return (Resolve-Path $bat).Path
        }
    }

    $fromPath = Get-Command flutter.bat -ErrorAction SilentlyContinue
    if ($fromPath) {
        return $fromPath.Source
    }
    throw "Flutter SDK not found. Pass -FlutterRoot or add flutter.bat to PATH."
}

function Resolve-Iscc {
    foreach ($path in $IsccCandidates) {
        if ($path -and (Test-Path $path)) {
            return $path
        }
    }
    $fromPath = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($fromPath) {
        return $fromPath.Source
    }
    throw "Inno Setup 6 compiler (ISCC.exe) not found. Install Inno Setup 6."
}

function Assert-NativeArtifacts {
    $required = @(
        (Join-Path $AppDir "libXray.dll"),
        (Join-Path $AppDir "OneXrayCore.exe"),
        (Join-Path $AppDir "wintun.dll")
    )
    $missing = $required | Where-Object { -not (Test-Path $_) }
    if ($missing) {
        $list = $missing -join "`n  "
        throw @"
Missing Windows native artifacts:
  $list

Copy libXray.dll, OneXrayCore.exe, and wintun.dll into windows\app\
as described in readme\FIRST_RUN.md.
"@
    }
}

function Invoke-FlutterBuild([string] $FlutterBat) {
    Write-Step "flutter pub get"
    & $FlutterBat pub get
    if ($LASTEXITCODE -ne 0) {
        throw "flutter pub get failed with exit code $LASTEXITCODE"
    }

    Write-Step "flutter build windows --release (x64)"
    & $FlutterBat build windows --release
    if ($LASTEXITCODE -ne 0) {
        throw "flutter build windows failed with exit code $LASTEXITCODE"
    }
}

function Assert-ReleaseBundle {
    $exe = Join-Path $ReleaseDir "OneXray.exe"
    $core = Join-Path $ReleaseDir "bin\OneXrayCore.exe"
    $lib = Join-Path $ReleaseDir "libXray.dll"
    $wintun = Join-Path $ReleaseDir "bin\wintun.dll"
    foreach ($path in @($exe, $core, $lib, $wintun)) {
        if (-not (Test-Path $path)) {
            throw "Release bundle is incomplete: $path"
        }
    }
}

function New-SetupScript([string] $OutputBaseName) {
    $sourceDir = $ReleaseDir
    $icon = $IconFile
    $languages = @(
        'Name: "english"; MessagesFile: "compiler:Default.isl"'
    )
    $zhIsl = Join-Path (Split-Path (Resolve-Iscc)) "Languages\ChineseSimplified.isl"
    if (Test-Path $zhIsl) {
        $languages += 'Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"'
    }

    $languageBlock = $languages -join "`r`n"

    return @"
#define MyAppName "OneXray"
#define MyAppPublisher "YuanDevLLC"
#define MyAppURL "https://github.com/OneXray/OneXray"
#define MyAppExeName "OneXray.exe"

[Setup]
AppId={{835d7bbd-85bb-4c73-97f8-ce0740f151a7}
AppName={#MyAppName}
AppVersion=$($script:MarketingVersion)
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\OneXray
DisableProgramGroupPage=yes
OutputDir=$DistDir
OutputBaseFilename=$OutputBaseName
Compression=lzma
SolidCompression=yes
SetupIconFile=$icon
WizardStyle=modern
PrivilegesRequired=admin
UsedUserAreasWarning=no
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
$languageBlock

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce
Name: "launchAtStartup"; Description: "{cm:AutoStartProgram,{#MyAppName}}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "$sourceDir\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{userstartup}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: launchAtStartup

[Registry]
Root: HKCU; Subkey: "Software\Classes\onexray"; ValueType: string; ValueName: ""; ValueData: "URL:OneXray Protocol"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\onexray"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\onexray\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"",0"
Root: HKCU; Subkey: "Software\Classes\onexray\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: runascurrentuser nowait postinstall skipifsilent
"@
}

function Invoke-InnoSetup([string] $Iscc, [string] $IssPath) {
    Write-Step "Compile installer with Inno Setup"
    & $Iscc $IssPath
    if ($LASTEXITCODE -ne 0) {
        throw "ISCC failed with exit code $LASTEXITCODE"
    }
}

$script:MarketingVersion = Get-MarketingVersion
$OutputBaseName = "oneXray-setup-v$($script:MarketingVersion)"
$InstallerPath = Join-Path $DistDir "$OutputBaseName.exe"

Write-Step "OneXray Windows x64 installer"
Write-Host "Repo:     $RepoRoot"
Write-Host "Version:  $($script:MarketingVersion)"
Write-Host "Output:   $InstallerPath"

Assert-NativeArtifacts
New-Item -ItemType Directory -Force -Path $DistDir | Out-Null

if (-not $SkipFlutterBuild) {
    $flutterBat = Resolve-FlutterBat
    Write-Host "Flutter:  $flutterBat"
    Invoke-FlutterBuild $flutterBat
} else {
    Write-Step "Skipping Flutter build"
}

Assert-ReleaseBundle

$iscc = Resolve-Iscc
$issPath = Join-Path $DistDir "oneXray-setup.iss"
$iss = New-SetupScript $OutputBaseName
# Inno Setup expects UTF-8 with BOM for non-ASCII language names.
$utf8Bom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($issPath, $iss, $utf8Bom)

try {
    Invoke-InnoSetup $iscc $issPath
} finally {
    if (Test-Path $issPath) {
        Remove-Item $issPath -Force
    }
}

if (-not (Test-Path $InstallerPath)) {
    throw "Installer was not created: $InstallerPath"
}

$item = Get-Item $InstallerPath
Write-Step "Done"
Write-Host ("Created {0} ({1:N1} MB)" -f $item.FullName, ($item.Length / 1MB))
