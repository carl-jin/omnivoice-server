# Desktop installers (dmg / exe)

Build scripts that freeze `omnivoice-server` into a standalone bundle and wrap it
in a native installer, so end users don't need Python or `pip`.

| Target | Output | torch wheel |
|--------|--------|-------------|
| macOS (Apple Silicon) | `OmniVoice-Server-<ver>-macos-arm64.dmg` | CPU (MPS unsupported upstream) |
| Windows CPU | `OmniVoice-Server-<ver>-windows-cpu-setup.exe` | `cpu` |
| Windows + NVIDIA | `OmniVoice-Server-<ver>-windows-cuda-setup.exe` | `cu128` |

## Key facts

- **The ~3GB TTS model is not bundled.** It downloads from HuggingFace
  (`k2-fsa/OmniVoice`) into the per-user cache on first launch. Installers stay
  ~1.5–2GB (CPU) / ~3–4GB (CUDA).
- **One-dir, not one-file.** torch is multiple GB; a one-file build would unpack
  everything to a temp dir on every launch.
- **No cross-compilation.** macOS builds the dmg, Windows builds the exe. Use the
  GitHub Actions workflow (`.github/workflows/build-installers.yml`) to build all
  three on hosted runners — the CUDA build does *not* need a GPU to compile.

## Files

- `launcher.py` — frozen-app entry point (calls `freeze_support()` then the CLI).
- `omnivoice-server.spec` — shared PyInstaller spec (collects torch / transformers
  / librosa / omnivoice, excludes the gradio demo stack).
- `build_macos.sh` — freeze + `hdiutil` dmg.
- `build_windows.ps1` — freeze + Inno Setup, `-Variant cpu|cuda`.
- `omnivoice-server.iss` — Inno Setup installer definition.
- `macos/` — dmg payload (launcher `.command` + README).

## Local build

macOS:

```bash
python3.12 -m venv .venv && source .venv/bin/activate
pip install torch==2.8.0 torchaudio==2.8.0
pip install . pyinstaller
bash packaging/build_macos.sh
```

Windows (PowerShell):

```powershell
py -3.12 -m venv .venv; .\.venv\Scripts\Activate.ps1
pip install . pyinstaller
.\packaging\build_windows.ps1 -Variant cpu   # or cuda
```

> Use Python 3.12. torch 2.8.0 has no wheels for 3.13+/3.14 yet.

## Notes / limitations

- **macOS Gatekeeper**: builds are ad-hoc signed only. For distribution to other
  machines without the right-click→Open dance, sign + notarize with a paid Apple
  Developer ID.
- **Windows SmartScreen**: unsigned installers show a warning. Sign with an
  Authenticode cert to remove it.
- **mp3/opus/aac/flac output** needs ffmpeg on PATH (via the `formats` extra).
  WAV output works out of the box.
