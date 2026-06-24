# -*- mode: python ; coding: utf-8 -*-
"""Shared PyInstaller spec for omnivoice-server (macOS + Windows).

Build (from repo root, inside the build venv):
    pyinstaller packaging/omnivoice-server.spec --noconfirm

Produces a one-dir bundle under ``dist/omnivoice-server/``. One-dir (not
one-file) is deliberate: torch alone is multiple GB and a one-file build would
unpack the whole thing to a temp dir on every launch.

The TTS model itself is NOT bundled — it is downloaded from HuggingFace into the
per-user cache on first run.
"""

import os

from PyInstaller.utils.hooks import collect_all, collect_submodules

# SPECPATH is injected by PyInstaller; resolve the entry point relative to this
# spec so the build works regardless of the current working directory.
ENTRY = os.path.join(SPECPATH, "launcher.py")

datas: list = []
binaries: list = []
hiddenimports: list = []

# Heavy native packages: pull in their data files, shared libs, and submodules.
# omnivoice 0.1.x drags in transformers / accelerate / librosa at import time, so
# those must be bundled too. gradio is intentionally excluded below — it is only
# used by omnivoice's own demo CLI, never on the TTS model path.
for pkg in (
    "torch",
    "torchaudio",
    "omnivoice",
    "transformers",
    "accelerate",
    "librosa",
    "soundfile",
    "huggingface_hub",
    "pydantic",
    "pydantic_settings",
):
    d, b, h = collect_all(pkg)
    datas += d
    binaries += b
    hiddenimports += h

# librosa pulls numba/llvmlite, which are loaded lazily and missed by static
# analysis. tokenizers/safetensors back transformers' fast paths.
hiddenimports += [
    "numba",
    "llvmlite",
    "tokenizers",
    "safetensors",
    "sklearn.utils._typedefs",
    "sklearn.neighbors._partition_nodes",
]

# uvicorn[standard] resolves its event loop / HTTP / websocket implementations
# dynamically at runtime, so PyInstaller's static analysis misses them.
hiddenimports += collect_submodules("uvicorn")
hiddenimports += [
    "uvicorn.lifespan.on",
    "uvicorn.lifespan.off",
    "uvicorn.loops.auto",
    "uvicorn.loops.asyncio",
    "uvicorn.protocols.http.auto",
    "uvicorn.protocols.http.h11_impl",
    "uvicorn.protocols.websockets.auto",
    "uvicorn.protocols.websockets.websockets_impl",
]

# Our own package (routers/services are imported by string in some FastAPI paths).
hiddenimports += collect_submodules("omnivoice_server")

a = Analysis(
    [ENTRY],
    pathex=[],
    binaries=binaries,
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        "tkinter",
        "matplotlib",
        "PIL",
        "pytest",
        "IPython",
        # gradio stack: only omnivoice's demo CLI uses it, not the server.
        "gradio",
        "gradio_client",
        "hf_gradio",
        "safehttpx",
        "groovy",
    ],
    noarchive=False,
    optimize=0,
)

pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name="omnivoice-server",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=False,
    upx_exclude=[],
    name="omnivoice-server",
)
