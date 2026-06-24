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

# Optional runtime smoke test of the frozen bundle (set OMNIVOICE_SMOKE_TEST=1).
# Boots the exe, waits for readiness (first run downloads the ~3GB model),
# checks /health and synthesizes a tiny clip. Skipped by default so local
# builds don't trigger the big download.
if ($Env:OMNIVOICE_SMOKE_TEST -eq "1") {
    Write-Host "==> Smoke test: booting frozen server"
    $Exe = "dist\omnivoice-server\omnivoice-server.exe"
    $Env:OMNIVOICE_HOST = "127.0.0.1"
    $Env:OMNIVOICE_PORT = "8899"
    $Env:OMNIVOICE_DEVICE = "cpu"
    $OutLog = "smoke.out.log"
    $ErrLog = "smoke.err.log"
    Remove-Item $OutLog, $ErrLog, "smoke.wav" -ErrorAction SilentlyContinue

    $proc = Start-Process -FilePath $Exe -PassThru -NoNewWindow `
        -RedirectStandardOutput $OutLog -RedirectStandardError $ErrLog

    $ready = $false
    for ($i = 0; $i -lt 300; $i++) {
        if ($proc.HasExited) {
            Write-Host "!! server exited early (code $($proc.ExitCode))"
            Get-Content $OutLog, $ErrLog -ErrorAction SilentlyContinue
            throw "smoke test: server died during startup"
        }
        if ((Test-Path $OutLog) -and (Select-String -Path $OutLog -Pattern "OMNIVOICE_READY" -Quiet)) {
            $ready = $true; break
        }
        Start-Sleep -Seconds 5
    }
    if (-not $ready) {
        Get-Content $OutLog, $ErrLog -ErrorAction SilentlyContinue
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        throw "smoke test: server not ready in time"
    }

    Write-Host "--- /health ---"
    $health = Invoke-RestMethod "http://127.0.0.1:8899/health"
    Write-Host ($health | ConvertTo-Json -Compress)

    Write-Host "--- /v1/audio/speech ---"
    $body = '{"model":"omnivoice","input":"Hello from a frozen Windows build."}'
    Invoke-WebRequest "http://127.0.0.1:8899/v1/audio/speech" -Method Post `
        -ContentType "application/json" -Body $body -OutFile "smoke.wav" | Out-Null
    $size = (Get-Item "smoke.wav").Length
    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue

    if ($size -lt 1000) { throw "smoke test: speech wav too small ($size bytes)" }
    Write-Host "==> SMOKE TEST PASS (wav $size bytes)"
}

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
