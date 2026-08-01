# Burning Steel — Mech & Warband Builder

A single-file, offline-capable builder for the *Revised Burning Steel* tabletop rules.
No install, no account, nothing to download — it runs entirely in the browser and
saves your builds locally on your own device.

**Play it here:** https://noltari13.github.io/burning-steel/

## What it does

- **Frame designer** — spend Frame Points on HP, weight, energy, hardpoints,
  movement and systems, including the alternate weight/energy payments.
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
(HP, Dv, heat capacity, cooling, to-hit). A "Rules variant" dropdown at the top
of the page switches the whole builder between rulesets instantly; the choice is
stamped on exports and printed sheets. Ships with **Derived stats**: +1 HP per
weight rank, +1 Dv per 5 weight (Armored Plates removed), +1 heat cap per
2 energy, +1 COOLING per 5 energy, +1 to hit per 4 systems, and the
alternative rank payments (HP via weight, movement/systems via weight or
energy) are disabled — weight and energy already pay out through the derived
stats. **Derived stats + weight classes** adds frame classes on top: weight
1–3 is Light (+1 M, may exceed the rank cap), 4–6 Medium, 7+ Heavy (−1 M).
Copy a block to try the next idea.

`mech_calculator_v2.html` is the earlier single-mech-only version, kept for reference.
