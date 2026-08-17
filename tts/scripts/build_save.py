#!/usr/bin/env python3
"""Build save/BurningSteel.json — the TTS mod savegame.

Embeds build/Global.lua and src/Global.xml, sets up the hex grid, and seeds
the table with d10s, the two reference cards, and the three infinite card
bags (order / partial order / pass) that Round Setup deals from.

TTS fills in any fields a save file omits, so this stays minimal on purpose.
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

# --local: use file:/// URLs to the repo's own PNGs instead of GitHub Pages.
# Only works on this machine (fine for solo testing; rebuild without the flag
# for anything you'll play with someone else or publish).
LOCAL = "--local" in sys.argv

ASSET_BASE = None
for line in (ROOT / "src/global/00_config.lua").read_text().splitlines():
    m = re.match(r'ASSET_VERSION\s*=\s*"([^"]+)"', line.strip())
    if m:
        if LOCAL:
            win_path = str(ROOT / "assets/png" / m.group(1))
            win_path = re.sub(r"^/mnt/([a-z])", lambda w: w.group(1).upper() + ":",
                              win_path)
            ASSET_BASE = "file:///" + win_path
        else:
            ASSET_BASE = ("https://noltari13.github.io/burning-steel/tts/assets/png/"
                          + m.group(1))
if not ASSET_BASE:
    raise SystemExit("ASSET_VERSION not found in 00_config.lua")

GRID_X = 2.0


def transform(x, z, y=1.5, rot_y=180.0, scale=1.0):
    return {"posX": x, "posY": y, "posZ": z,
            "rotX": 0.0, "rotY": rot_y, "rotZ": 0.0,
            "scaleX": scale, "scaleY": scale, "scaleZ": scale}


def d10(guid, x, z, color):
    return {
        "GUID": guid, "Name": "Die_10", "Transform": transform(x, z),
        "Nickname": "", "ColorDiffuse": color,
        "Locked": False, "Grid": False, "Snap": False,
    }


def custom_card(guid, deck_id, nickname, description, face, x, z, tags=None):
    return {
        "GUID": guid, "Name": "CardCustom", "Transform": transform(x, z),
        "Nickname": nickname, "Description": description,
        "Grid": False, "Snap": False,
        "CardID": deck_id * 100,
        "CustomDeck": {str(deck_id): {
            "FaceURL": f"{ASSET_BASE}/{face}.png",
            "BackURL": f"{ASSET_BASE}/card_back.png",
            "NumWidth": 1, "NumHeight": 1,
            "BackIsHidden": True, "UniqueBack": False,
        }},
        **({"Tags": tags} if tags else {}),
    }


def infinite_bag(guid, tag, nickname, card):
    card = dict(card)
    card["Transform"] = transform(0, 0)
    return {
        "GUID": guid, "Name": "Infinite_Bag", "Transform": transform(*BAG_POS.pop(0)),
        "Nickname": nickname,
        "Description": "Round Setup deals from this bag. Do not delete; do not remove the tag.",
        "Tags": [tag], "Grid": False, "Snap": False,
        "ColorDiffuse": BAG_COLOR.pop(0),
        "ContainedObjects": [card],
    }


BAG_POS = [(-26.0, 14.0), (-26.0, 10.0), (-26.0, 6.0)]
BAG_COLOR = [{"r": 0.11, "g": 0.21, "b": 0.34},
             {"r": 0.36, "g": 0.20, "b": 0.09},
             {"r": 0.23, "g": 0.25, "b": 0.29}]

objects = [
    # Dice — three per side
    d10("bsd101", 24.0, -12.0, {"r": 0.85, "g": 0.3, "b": 0.3}),
    d10("bsd102", 26.0, -12.0, {"r": 0.85, "g": 0.3, "b": 0.3}),
    d10("bsd103", 28.0, -12.0, {"r": 0.85, "g": 0.3, "b": 0.3}),
    d10("bsd104", 24.0, 12.0, {"r": 0.3, "g": 0.45, "b": 0.85}),
    d10("bsd105", 26.0, 12.0, {"r": 0.3, "g": 0.45, "b": 0.85}),
    d10("bsd106", 28.0, 12.0, {"r": 0.3, "g": 0.45, "b": 0.85}),
    # Reference cards
    custom_card("bsr201", 20, "Threshold table",
                "Roll on overheat, at 1/2 HP and at 1/4 HP.",
                "ref_threshold", -26.0, -6.0),
    custom_card("bsr202", 21, "Attack table",
                "Av = d10 + modifiers, compared to Dv.",
                "ref_attack", -26.0, -10.0),
    custom_card("bsr203", 22, "Turn quick reference",
                "2 AP + 1 reaction: attacks, movement, other actions, reactions.",
                "ref_actions", -26.0, -14.0),
    # Card bags for Round Setup
    infinite_bag("bsb301", "BS_BAG_ORDER", "Order cards",
                 custom_card("bsc311", 30, "Order", "2 AP + 1 reaction. Only this mech.",
                             "card_order", 0, 0)),
    infinite_bag("bsb302", "BS_BAG_PARTIAL", "Partial order cards",
                 custom_card("bsc312", 31, "Partial order", "1 AP + 1 heat. Any mech.",
                             "card_partial", 0, 0)),
    infinite_bag("bsb303", "BS_BAG_PASS", "Pass cards",
                 custom_card("bsc313", 32, "Pass", "Other player becomes active. Turn number unchanged.",
                             "card_pass", 0, 0)),
]

save = {
    "SaveName": "Burning Steel",
    "GameMode": "Burning Steel",
    "Gravity": 0.5,
    "PlayArea": 0.5,
    "Table": "Table_Square",
    "Sky": "Sky_Museum",
    "Note": "Burning Steel — hex mecha skirmish. Toolbar (right): Import Warband / Round Setup / templates / Attack Roller.",
    "Rules": "",
    "Grid": {
        # Type 2 = hex horizontal (flat-top). If Options > Grid in-game shows
        # pointy-top hexes, switch it there and re-save (see tts/README.md).
        "Type": 2,
        "Lines": True,
        "Color": {"r": 0.0, "g": 0.0, "b": 0.0},
        "Opacity": 0.6,
        "ThickLines": False,
        "Snapping": 2,          # snap to hex centers
        "Offset": False,
        "BoldedLines": False,
        "xSize": GRID_X,
        "ySize": GRID_X,
        "PosOffset": {"x": 0.0, "y": 1.0, "z": 0.0},
    },
    # In --local mode the Lua config's ASSET_BASE (used for spawning
    # templates) is overridden after the bundle, same URL as the objects.
    "LuaScript": (ROOT / "build/Global.lua").read_text()
    + (f'\nASSET_BASE = "{ASSET_BASE}"  -- --local build\n' if LOCAL else ""),
    "LuaScriptState": "",
    "XmlUI": (ROOT / "src/Global.xml").read_text(),
    "ObjectStates": objects,
}

out = ROOT / "save/BurningSteel.json"
out.write_text(json.dumps(save, indent=2))
mode = "LOCAL file:/// assets (this machine only)" if LOCAL else "GitHub Pages assets"
print(f"Wrote {out} ({out.stat().st_size // 1024} KB, {len(objects)} objects, {mode})")
