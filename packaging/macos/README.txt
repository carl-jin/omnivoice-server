OmniVoice Server (macOS)
========================

OpenAI-compatible HTTP server for OmniVoice text-to-speech.

INSTALL
-------
1. Drag the "OmniVoice Server" folder into your Applications folder
   (or anywhere you like).
2. Double-click "Start OmniVoice Server.command".
   - The first launch downloads the ~3GB TTS model from HuggingFace.
     This needs an internet connection and only happens once.
   - macOS may warn that the app is from an unidentified developer.
     If so: right-click the .command -> Open -> Open.

USE
---
Once you see "OMNIVOICE_READY", the API is live at:

    http://127.0.0.1:8880

Example:

    curl -X POST http://127.0.0.1:8880/v1/audio/speech \
      -H "Content-Type: application/json" \
      -d '{"model":"omnivoice","input":"Hello world!"}' \
      --output speech.wav

Interactive API docs: http://127.0.0.1:8880/docs

NOTES
-----
- Apple Silicon runs on CPU (the MPS backend is not yet supported upstream),
  so synthesis is slower than realtime. This is expected.
- To stop the server, press Ctrl-C in the Terminal window.
