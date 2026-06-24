"""Frozen-app entry point for omnivoice-server.

PyInstaller uses this as the analysis entry. It must call
``multiprocessing.freeze_support()`` before anything else so that any worker
processes spawned by torch / the stdlib re-exec cleanly inside the frozen
bundle instead of re-running the server.
"""

from __future__ import annotations

import multiprocessing


def _run() -> None:
    from omnivoice_server.cli import main

    main()


if __name__ == "__main__":
    multiprocessing.freeze_support()
    _run()
