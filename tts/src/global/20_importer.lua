-- ==================================================================
-- 20_importer — paste a builder "Export for TTS" JSON, spawn stat tiles
-- ==================================================================
IMPORT_TEXT = ""

function onImportTextChanged(player, value, id)
  IMPORT_TEXT = value or ""
end

function uiImportOpen(player)
  UI.show("importPanel")
end

function uiImportClose(player)
  UI.hide("importPanel")
end

function uiImportConfirm(player)
  local color = player.color
  if color == "Grey" or color == "Black" then
    bsError("Pick a seat (a player color) before importing a warband.")
    return
  end
  local ok, data = pcall(JSON.decode, bsCleanJson(IMPORT_TEXT))
  if not ok or type(data) ~= "table" then
    bsError("That is not valid JSON. Copy the whole file from the builder's Export for TTS button.")
    return
  end
  if data.format ~= "burning-steel-tts" then
    bsError("Wrong file: use the builder's \"Export for TTS\" button (not the plain warband export).")
    return
  end
  if (data.ttsVersion or 0) > 1 then
    bsWarn("This export is ttsVersion " .. tostring(data.ttsVersion) .. "; this mod understands 1. Trying anyway.")
  end
  if type(data.mechs) ~= "table" or #data.mechs == 0 then
    bsError("The export contains no mechs.")
    return
  end
  UI.hide("importPanel")
  local n = #data.mechs
  for i, mech in ipairs(data.mechs) do
    spawnStatTile(mech, data, color, i, n)
  end
  bsInfo(color .. " imported \"" .. (data.name or "warband") .. "\" — " .. n ..
         " mech" .. (n > 1 and "s" or "") .. " (rules: " .. (data.variant or "core") .. ").")
end

-- Full sheet text shown when hovering the tile (object description).
function sheetDescription(mech)
  local st = mech.stats or {}
  local L = {}
  table.insert(L, string.format("%s — HP %s, Dv %s, M %s, S %s, Heat Cap %s%s",
    mech.wclass or "?", st.hp or "?", st.dv or "?", st.m or "?", st.s or "?",
    st.heatCap or "?", st.overdrive and " (Overdrive)" or ""))
  table.insert(L, string.format("Slam: rng 1, 1 shot, -2 acc, %s dmg | SysDef %s | COOLING removes %s%s",
    st.slamDmg or "?", st.sysDef or "?", st.cooling or "?",
    (st.hitBonus or 0) > 0 and (" | Weapon attacks +" .. st.hitBonus .. " to hit") or ""))
  local function section(title, items, fmt)
    if items and #items > 0 then
      table.insert(L, "")
      table.insert(L, "[b]" .. title .. "[/b]")
      for _, it in ipairs(items) do table.insert(L, fmt(it)) end
    end
  end
  section("Equipment", mech.equipment, function(e)
    return "- " .. e.name .. ((e.count or 1) > 1 and (" x" .. e.count) or "") .. " — " .. (e.fx or "")
  end)
  section("Weapons",  mech.weapons,  function(w) return "- " .. (w.line or w.name) end)
  section("Missiles", mech.missiles, function(m) return "- " .. (m.line or m.name) end)
  section("Programs", mech.programs, function(p) return "- " .. (p.line or p.name) end)
  section("Notes", mech.notes, function(x) return "- " .. x end)
  section("ILLEGAL BUILD", mech.warnings, function(x) return "- " .. x end)
  return table.concat(L, "\n")
end

function spawnStatTile(mech, data, color, i, n)
  local ht = Player[color].getHandTransform()
  local pos
  if ht then
    local f, r = ht.forward, ht.right
    local off = (i - 1) - (n - 1) / 2
    pos = {
      x = ht.position.x + f.x * 8 + r.x * off * (TILE_SX + 0.6),
      y = 2,
      z = ht.position.z + f.z * 8 + r.z * off * (TILE_SX + 0.6),
    }
  else
    pos = { x = ((i - 1) - (n - 1) / 2) * (TILE_SX + 0.6), y = 2, z = 0 }
  end
  local tile = spawnObject({
    type = "BlockSquare",
    position = pos,
    rotation = { 0, ht and (math.deg(math.atan2(ht.forward.x, ht.forward.z)) + 180) or 180, 0 },
    scale = { TILE_SX, TILE_SY, TILE_SZ },
    sound = false,
    callback_function = function(o)
      o.setName((mech.name or "Mech") .. " [" .. (mech.wclass or "?") .. "]")
      o.setDescription(sheetDescription(mech))
      o.setColorTint({ 0.85, 0.85, 0.82 })
      o.addTag(TAG_MECH)
      o.addTag("BS_" .. color)
      if mech.stats and mech.stats.overdrive then o.addTag(TAG_OVERDRIVE) end
      o.setGMNotes(JSON.encode(mech))
      o.setLuaScript(STATTILE_SCRIPT)
    end,
  })
  return tile
end
