#!/usr/bin/env bash
# Copy the built save into the Windows TTS Saves folder (run from WSL).
set -euo pipefail
cd "$(dirname "$0")/.."

DEST=""
for d in /mnt/c/Users/*/Documents/"My Games"/"Tabletop Simulator"/Saves; do
  [ -d "$d" ] && DEST="$d" && break
done
if [ -z "$DEST" ]; then
  echo "Could not find the TTS Saves folder under /mnt/c/Users/*/Documents/My Games/Tabletop Simulator/Saves" >&2
  echo "Install/run TTS once on Windows first, or copy tts/save/BurningSteel.json there by hand." >&2
  exit 1
fi
cp save/BurningSteel.json "$DEST/BurningSteel.json"
echo "Deployed to: $DEST/BurningSteel.json"
echo "In TTS: Games > Save & Load > BurningSteel."
