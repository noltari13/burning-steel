# Burning Steel — Mech & Warband Builder

A single-file, offline-capable builder for the *Burning Steel* tabletop rules
(current with the **2026-08-05 ruleset**). No install, no account, nothing to
download — it runs entirely in the browser and saves your builds locally on
your own device.

**Play it here:** https://noltari13.github.io/burning-steel/

## What it does

- **Frame designer** — spend Frame Points on HP, weight, energy, hardpoints,
  movement and systems, with the derived stats computed live: weight class
  from FP invested (shiftable with Min/Max Frame), +2 HP per weight rank,
  heat capacity from energy, weapon to-hit from systems, slam damage from
  weight class, and tiered FP credit pricing (1 cr each to 20, 2 cr for
  21–40, 3 cr for 41–60).
- **Equipment, weapon, missile and hacking kits** — full point budgets with live
  validation, so an illegal build tells you exactly what's wrong.
- **Duplicate buttons** — copy a weapon kit, missile type, program or a whole mech
  with every setting intact. Handy for twin-linked loadouts and identical chassis.
- **Warband mode** — set a team credit budget (200 small / 400 medium / 800 large),
  build a roster of mechs against it, and save, export or print the whole team at once.
- **Printable sheets** — one clean sheet per mech, plus a roster page in warband mode.

## Saving your work

Builds are stored in your browser's local storage, so they survive updates to the
site but do not follow you to another device or browser. Use **Export JSON** /
**Export warband JSON** to move a build or team between devices, or to share one
with another player.

## For the designer

All game numbers live in one block near the top of `index.html` — search for
`GAME DATA`. Cost tables, equipment, weapon modules, missile payloads and program
effects are plain lists; edit a value, save, refresh. Instructions are commented
inline.

**Rule variants** — right below the game data, search for `RULE VARIANTS`. Each
variant is a small block that can remove equipment and adjust derived stats
(HP, Dv, heat capacity, cooling, to-hit). A "Rules variant" dropdown appears at
the top of the page whenever more than one variant exists; the choice is
stamped on exports and printed sheets. The old **Derived stats** and
**Derived stats + weight classes** playtest variants were adopted into the
2026-08-05 rulebook (in revised form) and removed — add a new block next to
`core` to playtest the next idea.

Older saves load cleanly: renamed weapon mods are migrated (Energetic →
Reactor Linked, Air Burst → Zeroed), equipment that no longer exists
(Armored Plates, Heat Sinks) is dropped, out-of-range stat ranks are clamped
(movement now tops out at 5), and the removed alternative rank payments are
stripped — the validation panel flags anything that no longer fits.

`mech_calculator_v2.html` is the earlier single-mech-only version, kept for reference.

## Tabletop Simulator

The `tts/` folder holds a Tabletop Simulator mod for playing Burning Steel
online: build a warband here, click **Export for TTS** (Warband mode), and
paste the file into the mod's Import panel to get scripted stat sheets with
HP/heat/ammo counters, order-card dealing, area templates and an attack
roller. See `tts/README.md` for setup.
