# Burning Steel — Tabletop Simulator mod

A Tier-2 quality-of-life mod: it imports warbands from the web builder and
handles bookkeeping (counters, order cards, templates, dice), but automates no
rules — LoS, movement and effects are resolved by the players, like on a real
table.

## How a TTS mod works (30-second version)

A TTS "mod" is just a **savegame JSON**. It contains a global Lua script
(`LuaScript`), a global XML UI (`XmlUI`), and a list of objects; images are
loaded from URLs at run time. This folder keeps the sources in the repo and
builds that savegame:

```
src/global/*.lua    numbered sections, concatenated into one Global.lua
src/Global.xml      the on-screen UI (toolbar, import panel, attack roller)
assets/src/*.html   open in a browser -> draws the PNGs and offers downloads
assets/png/v1/      generated images, served by GitHub Pages
scripts/bundle.sh   concat Lua + rebuild save/BurningSteel.json
scripts/deploy.sh   copy the save into the Windows TTS Saves folder
save/BurningSteel.json   the deliverable (checked in)
```

## First-time setup

1. On Windows, install Tabletop Simulator (Steam) and run it once.
2. In WSL: `tts/scripts/bundle.sh && tts/scripts/deploy.sh`
3. In TTS: **Games → Save & Load → BurningSteel**.
4. Verify the grid (one time): **Options → Grid** should show a **hex** grid,
   **flat-top** hexes, **snap to center**, size 2. If the hexes are pointy-top,
   switch the hex type there, then **Save** over the same slot.
5. The images under `assets/png/` must be **pushed to GitHub** (they are served
   from `https://noltari13.github.io/burning-steel/tts/assets/png/v1/`).
   Until the push is live (~1 min after push), cards and templates show white.

## Playing

- **Import Warband** (toolbar): in the builder's Warband mode click
  **Export for TTS**, open the downloaded `.tts.json` in a text editor, copy
  everything, paste into the panel, Import. One stat tile spawns per mech in
  front of your seat — hover a tile for the full sheet; the buttons track
  HP / heat / every ammo pool (right-click ± for bigger steps). The tile
  announces ½ HP, ¼ HP and overheating, turns red while overheating, and has a
  DEAD toggle.
- **Link a model**: press **Link** on a stat tile, then pick up your miniature
  (or select the mini first for an instant link). The model gets the sheet as
  its hover description, a live name showing current HP/heat, a right-click
  menu (±HP, ±heat, Cooling, Unlink) and a red highlight while overheating;
  clicking the tile's name bar flashes the linked model. Links survive
  save/load, but a *replaced* model (new copy from a bag) must be re-linked.
- **Round Setup** (toolbar): deals each seated color 1 order card per live
  mech (Overdrive mechs get 2, and none when destroyed), 1 partial order per
  DEAD mech, and pass cards to the side with fewer cards. Cards come from the
  three tagged infinite bags on the table — don't delete them. Lay used cards
  left→right as the timeline.
- **T / S / M / L** buttons: spawn area templates (they snap to the grid).
  If a template doesn't sit exactly on the hexes, adjust `TEMPLATE_TUNE` in
  `src/global/50_templates.lua` and rebuild.
- **Attack Roller**: shots, accuracy, target Dv, damage per shot → per-die
  results and total damage in chat. Dv includes evasion/cover; accuracy
  includes the mech's to-hit bonus (both printed on the stat tile).
- Terrain: use stock hex tiles and blocks stacked to real height (rules
  default: terrain height 3), then eyeball LoS with the TTS line tool (hold
  the measure tool). Textures for Custom Tiles are in `assets/png/v1/` if you
  want prettier terrain.

## Development loop

Fast path (all from WSL):

1. Edit `src/global/*.lua` or `src/Global.xml`.
2. `scripts/bundle.sh && python3 scripts/update_save.py`
   — patches the **deployed** save in place: only the scripts change; your
   table, minis and spawned tiles (with their counter state) are preserved.
   Add `--local` for file:/// assets. Use `scripts/deploy.sh` instead only
   when you want to reset the table to the generated baseline.
3. In TTS, load the save again (Games → Save & Load → BurningSteel).

Comfortable path (live reload, recommended once you're editing often):
install VS Code **on Windows** with the *Tabletop Simulator Lua* extension
(rolandostar). With the save loaded, "Get Scripts" pulls Global.lua/XML from
the running game and "Save & Play" pushes and reloads instantly. The repo is
on `E:\`, so Windows VS Code and WSL edit the same files. If you change things
in-game (layout, terrain), Save in TTS, then copy the save back:
`cp "/mnt/c/Users/<you>/Documents/My Games/Tabletop Simulator/Saves/BurningSteel.json" save/`
— but note that regenerating with `bundle.sh` **overwrites** `save/BurningSteel.json`
(it rebuilds from `build_save.py`), so fold any in-game layout you want to keep
into `scripts/build_save.py`, or stop regenerating the save and only update its
`LuaScript`/`XmlUI` via the VS Code extension.

Debugging: `print()` goes to the in-game console (the `~` key or the chat's
game tab); script errors appear in chat with line numbers counted in the
**bundled** `build/Global.lua` — the section banners make them easy to place.

## Assets

Open `assets/src/{cards,templates,tiles}.html` in a browser; each page draws
its PNGs and offers download links (rule text lives inside `cards.html`, ring
shapes inside `templates.html`). **TTS caches images by URL forever**: when an
image changes, put the new files in a NEW folder (`assets/png/v2/`), update
`ASSET_VERSION` in `src/global/00_config.lua`, rebuild, push. While testing you
can clear the local cache via **Mod Caching** in the TTS menu.
`templates.html` also prints the `TEMPLATE_SPANS` constants for
`50_templates.lua` — update them if the template geometry changes.

## Publishing to the Workshop (later)

With the save loaded: **Upload → Workshop**, add a thumbnail and description.
Updating later re-uploads over the same Workshop item. Subscribers get images
from GitHub Pages, so published versions must never have their PNGs moved.

## Data contract with the builder

The importer only accepts JSON with `"format": "burning-steel-tts"`, produced
by the builder's **Export for TTS** button (`ttsExport()` in `index.html`).
All derived stats and rule text are computed by the builder at export time —
the Lua renders strings and seeds counters, and never needs updating when game
data or rules variants change. If the snapshot schema ever changes shape,
bump `ttsVersion` in both `index.html` and the importer check.
