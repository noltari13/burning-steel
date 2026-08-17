#!/usr/bin/env python3
"""Patch an EXISTING TTS save in place with the latest scripts.

Unlike build_save.py (which regenerates the whole table), this keeps every
object — custom tables, minis, terrain — and only swaps:
  - the global LuaScript (from build/Global.lua; run bundle.sh first)
  - the global XmlUI (from src/Global.xml)
  - the per-object script of anything tagged BS_MECH (stat tiles), keeping
    each tile's counter state (LuaScriptState) and sheet (GMNotes) intact.

Usage:
  update_save.py [--local] [path-to-save.json]
With no path it patches BurningSteel.json in the Windows TTS Saves folder.
--local points ASSET_BASE at the repo's PNGs via file:/// (this machine only).
"""
import glob
import json
import pathlib
import re
import shutil
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LOCAL = "--local" in sys.argv
args = [a for a in sys.argv[1:] if a != "--local"]

if args:
    save_path = pathlib.Path(args[0])
else:
    hits = glob.glob("/mnt/c/Users/*/Documents/My Games/Tabletop Simulator/Saves/BurningSteel.json") \
         + glob.glob("/mnt/c/Users/*/OneDrive*/Documents/My Games/Tabletop Simulator/Saves/BurningSteel.json")
    if not hits:
        raise SystemExit("No deployed BurningSteel.json found; pass the save path explicitly.")
    save_path = pathlib.Path(hits[0])

lua = (ROOT / "build/Global.lua").read_text()
xml = (ROOT / "src/Global.xml").read_text()

if LOCAL:
    m = re.search(r'ASSET_VERSION\s*=\s*"([^"]+)"', lua)
    if not m:
        raise SystemExit("ASSET_VERSION not found in the bundle.")
    win = re.sub(r"^/mnt/([a-z])", lambda w: w.group(1).upper() + ":",
                 str(ROOT / "assets/png" / m.group(1)))
    lua += f'\nASSET_BASE = "file:///{win}"  -- --local build\n'

m = re.search(r"STATTILE_SCRIPT = \[==\[\n?(.*?)\]==\]", lua, re.S)
if not m:
    raise SystemExit("Could not extract STATTILE_SCRIPT from the bundle.")
tile_script = m.group(1)

save = json.loads(save_path.read_text())
save["LuaScript"] = lua
save["XmlUI"] = xml

patched = 0
def walk(objs):
    global patched
    for o in objs or []:
        if "BS_MECH" in (o.get("Tags") or []):
            o["LuaScript"] = tile_script
            patched += 1
        walk(o.get("ContainedObjects"))
        for st in (o.get("States") or {}).values():
            walk([st])
walk(save.get("ObjectStates"))

shutil.copy(save_path, str(save_path) + ".bak")
save_path.write_text(json.dumps(save, indent=2))
mode = "LOCAL file:/// assets" if LOCAL else "GitHub Pages assets"
print(f"Patched {save_path} ({mode}); {patched} stat tile(s) rescripted; backup at .bak")
print("In TTS: load the save again to pick the changes up.")
