<#
Build the Windows one-dir bundle with PyInstaller and wrap it in an Inno Setup
installer. Run from the repo root inside an activated build venv:

    pip install . pyinstaller
    .\packaging\build_windows.ps1 -Variant cpu
    .\packaging\build_windows.ps1 -Variant cuda

Output: dist\OmniVoice-Server-<version>-windows-<variant>-setup.exe

Requires Inno Setup 6 (ISCC.exe) on PATH or in its default location.
torch is installed here (not as a project dep) so the cpu / cu128 wheel split
is explicit.
#>
param(
    [ValidateSet("cpu", "cuda")]
    [string]$Variant = "cpu"
)

$ErrorActionPreference = "Stop"
$Repo = Split-Path -Parent $PSScriptRoot
Set-Location $Repo

Write-Host "==> Installing torch ($Variant)"
if ($Variant -eq "cuda") {
    pip install "torch==2.8.0" "torchaudio==2.8.0" --index-url https://download.pytorch.org/whl/cu128
} else {
    pip install "torch==2.8.0" "torchaudio==2.8.0" --index-url https://download.pytorch.org/whl/cpu
}

Write-Host "==> Installing project + PyInstaller"
pip install . "pyinstaller>=6.0"

Write-Host "==> PyInstaller freeze (onedir)"
pyinstaller packaging\omnivoice-server.spec --noconfirm --distpath dist --workpath build\pyi

$Version = (python -c "import omnivoice_server; print(omnivoice_server.__version__)").Trim()
Write-Host "==> Version: $Version"

# Locate Inno Setup compiler.
$Iscc = $null
foreach ($p in @(
        "${Env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "${Env:ProgramFiles}\Inno Setup 6\ISCC.exe")) {
    if (Test-Path $p) { $Iscc = $p; break }
}
if (-not $Iscc) {
    $cmd = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($cmd) { $Iscc = $cmd.Source }
}
if (-not $Iscc) { throw "ISCC.exe (Inno Setup 6) not found. Install it first." }

Write-Host "==> Compiling installer with $Iscc"
& $Iscc "/DMyVersion=$Version" "/DMyVariant=$Variant" packaging\omnivoice-server.iss

Write-Host "==> Done. Output in dist\"
Get-ChildItem dist\*setup.exe | ForEach-Object { Write-Host $_.FullName }
