#!/bin/bash
# Double-clickable launcher. Opens in Terminal and runs the bundled server.
# Stop the server with Ctrl-C.
DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="$DIR/omnivoice-server/omnivoice-server"
if [ ! -x "$BIN" ]; then
  echo "Could not find the omnivoice-server binary next to this launcher."
  echo "Make sure you copied the whole 'OmniVoice Server' folder, not just this file."
  read -r -p "Press Return to close."
  exit 1
fi
echo "Starting OmniVoice Server on http://127.0.0.1:8880  (first run downloads ~3GB model)"
echo "Press Ctrl-C to stop."
exec "$BIN" "$@"
