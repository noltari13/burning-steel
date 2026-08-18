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
  local models = modelBagData()
  for i, mech in ipairs(data.mechs) do
    local tile = spawnStatTile(mech, data, color, i, n)
    if #models > 0 then
      local mdl = spawnMechModel(mech, color, i, n, models)
      if mdl ~= nil then
        -- auto-link once the tile's injected script has initialized
        Wait.time(function()
          if tile ~= nil and mdl ~= nil then
            pcall(function() tile.call("completeLink", { guid = mdl.getGUID(), silent = true }) end)
          end
        end, 2)
      end
    end
  end
  bsInfo(color .. " imported \"" .. (data.name or "warband") .. "\" — " .. n ..
         " mech" .. (n > 1 and "s" or "") .. " (rules: " .. (data.variant or "core") .. ").")
  if #models > 0 then
    bsInfo("Each mech got a linked model with " .. #models ..
           " appearances — hover it and press number keys, or right-click > States, to change its look.")
  else
    bsInfo("Tip: tag a bag of miniatures with " .. TAG_MODELS ..
           " (Tags gizmo) and re-import to auto-spawn a scrollable model per mech.")
  end
end

-- ---------------- multi-state mech models ----------------
-- Reads every mini out of the bag(s) tagged BS_MODELS and packs them all
-- into ONE object per mech as alternate States (right-click > States or
-- hover + number keys to scroll). Appearance only — name/sheet/links are
-- reapplied on every switch by onObjectStateChange in Global.
function modelBagData()
  local out = {}
  for _, bag in ipairs(getObjectsWithTag(TAG_MODELS)) do
    local d = bag.getData()
    for _, c in ipairs(d.ContainedObjects or {}) do table.insert(out, c) end
  end
  return out
end

local function cleanModelData(src, mech)
  local d = JSON.decode(JSON.encode(src))   -- deep copy
  d.States = nil
  d.LuaScript, d.LuaScriptState, d.XmlUI = "", "", ""
  d.GUID = nil
  d.Nickname = mech.name
  d.Description = "Appearance: hover + number keys, or right-click > States."
  d.Locked = false
  d.Tags = { "BS_LINKED" }
  return d
end

function spawnMechModel(mech, color, i, n, models)
  local base = cleanModelData(models[1], mech)
  if #models > 1 then
    base.States = {}
    for j = 2, #models do
      base.States[tostring(j)] = cleanModelData(models[j], mech)
    end
  end
  local ht = Player[color].getHandTransform()
  local pos, yaw
  if ht then
    local f, r = ht.forward, ht.right
    local off = (i - 1) - (n - 1) / 2
    pos = {
      x = ht.position.x + f.x * 13 + r.x * off * (TILE_SX + 0.6),
      y = 2.5,
      z = ht.position.z + f.z * 13 + r.z * off * (TILE_SX + 0.6),
    }
    yaw = math.deg(math.atan2(f.x, f.z)) + 180
  else
    pos = { x = ((i - 1) - (n - 1) / 2) * (TILE_SX + 0.6), y = 2.5, z = 6 }
    yaw = 180
  end
  return spawnObjectData({ data = base, position = pos, rotation = { 0, yaw, 0 } })
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
      o.use_grid = false          -- stat tiles live beside the map, not on hexes
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
