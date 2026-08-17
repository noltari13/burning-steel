#!/usr/bin/env bash
# Bundle the Lua sections into build/Global.lua and rebuild the mod save.
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p build
: > build/Global.lua
for f in src/global/*.lua; do
  cat "$f" >> build/Global.lua
  echo "" >> build/Global.lua
done
echo "Bundled $(ls src/global/*.lua | wc -l) sections -> build/Global.lua ($(wc -l < build/Global.lua) lines)"

python3 scripts/build_save.py
