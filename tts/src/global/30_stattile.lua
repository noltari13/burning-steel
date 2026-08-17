-- ==================================================================
-- 30_stattile — per-object script injected into spawned stat tiles.
-- The tile reads its mech snapshot from GM Notes (immutable) and keeps
-- mutable counters in script_state, so state survives save/load and
-- copy/paste. Kept as one self-contained string: TTS has no require().
-- A tile can be LINKED to a miniature: the mini gets the sheet as its
-- hover description, a live name (HP/heat), a right-click bookkeeping
-- menu, and an overheat highlight. Link = press Link, then pick up (or
-- pre-select) the model. The link is a GUID in script_state.
-- ==================================================================
STATTILE_SCRIPT = [==[
-- Burning Steel stat tile (injected by the warband importer)
local SX, SY, SZ = 3.4, 0.2, 4.4   -- must match TILE_S* in Global 00_config
local BASE_TINT = {0.85, 0.85, 0.82}
local HOT_TINT  = {1.00, 0.42, 0.35}
local DEAD_TINT = {0.28, 0.28, 0.28}
local LINK_BTN = 2                 -- creation index of the Link button
local sheet, state
local rows = {}          -- {label, kind, key, max, step, valueBtn}

function isDead() return state ~= nil and state.dead == true end

function onLoad(saved)
  local ok, s = pcall(function() return JSON.decode(self.getGMNotes()) end)
  if not ok or type(s) ~= "table" or type(s.stats) ~= "table" then return end
  sheet = s
  if saved ~= nil and saved ~= "" then
    local ok2, st = pcall(function() return JSON.decode(saved) end)
    if ok2 and type(st) == "table" then state = st end
  end
  if state == nil then state = freshState() end
  buildRows()
  buildButtons()
  applyTint()
  if state.link then
    -- linked model may not have loaded yet; context menus don't persist
    Wait.frames(function() applyLink(true) end, 3)
  end
end

function onSave()
  if state == nil then return "" end
  return JSON.encode(state)
end

function freshState()
  local st = { hp = sheet.stats.hp, heat = 0, dead = false,
               half = false, quarter = false, hot = false, ammo = {} }
  for _, e in ipairs(sheet.equipment or {}) do
    if e.ammo ~= nil then st.ammo["E:" .. e.name] = e.ammo end
  end
  for _, m in ipairs(sheet.missiles or {}) do st.ammo["M:" .. m.name] = m.ammo end
  for _, p in ipairs(sheet.programs or {}) do st.ammo["P:" .. p.name] = p.ammo end
  return st
end

local function trim(s, n)
  if string.len(s) <= n then return s end
  return string.sub(s, 1, n - 2) .. ".."
end

function buildRows()
  rows = {}
  table.insert(rows, {label = "HP",   kind = "hp",   max = sheet.stats.hp,      step = 5})
  table.insert(rows, {label = "Heat", kind = "heat", max = sheet.stats.heatCap, step = 5})
  for _, e in ipairs(sheet.equipment or {}) do
    if e.ammo ~= nil then
      table.insert(rows, {label = trim(e.name, 16), kind = "ammo", key = "E:" .. e.name, max = e.ammo, step = 1})
    end
  end
  for _, m in ipairs(sheet.missiles or {}) do
    table.insert(rows, {label = trim(m.name, 16), kind = "ammo", key = "M:" .. m.name, max = m.ammoMax, step = 1})
  end
  for _, p in ipairs(sheet.programs or {}) do
    table.insert(rows, {label = trim(p.name, 16), kind = "ammo", key = "P:" .. p.name, max = p.ammoMax, step = 1})
  end
end

local function getVal(row)
  if row.kind == "hp" then return state.hp end
  if row.kind == "heat" then return state.heat end
  return state.ammo[row.key] or 0
end

-- Buttons live in the tile's local space; the tile is scaled (SX,SY,SZ),
-- so positions divide by the scale and button scale un-squashes the text.
local function bpos(wx, wz) return {wx / SX, 0.55, wz / SZ} end
local BSCALE = {1 / SX, 1, 1 / SZ}
local function W(u) return math.floor(u * 500) end

function buildButtons()
  self.clearButtons()
  self.createButton({click_function = "toggleDead", function_owner = self,
    label = state.dead and "DEAD" or "alive", position = bpos(1.35, -1.85),
    scale = BSCALE, width = W(0.62), height = W(0.34), font_size = W(0.15),
    color = state.dead and {0.5, 0.1, 0.1} or {0.2, 0.4, 0.2}, font_color = {1, 1, 1},
    tooltip = "Toggle destroyed. A destroyed mech makes a partial order card each round."})
  self.createButton({click_function = "pingMini", function_owner = self,
    label = trim(sheet.name or "Mech", 16), position = bpos(-0.85, -1.85),
    scale = BSCALE, width = W(1.6), height = W(0.36), font_size = W(0.16),
    color = {0.15, 0.15, 0.18}, font_color = {1, 1, 1},
    tooltip = "Hover the tile for the full sheet. Click to flash the linked model."})
  self.createButton({click_function = "linkClicked", function_owner = self,
    label = state.link and "Unlink" or "Link", position = bpos(0.5, -1.85),
    scale = BSCALE, width = W(0.62), height = W(0.34), font_size = W(0.14),
    color = {0.2, 0.3, 0.5}, font_color = {1, 1, 1},
    tooltip = "Tie this sheet to a miniature: select the model (or press, then pick the model up)."})
  local z0, z1 = -1.3, 1.95
  local step = 0.46
  if #rows > 1 then step = math.min(0.46, (z1 - z0) / (#rows - 1)) end
  for i, row in ipairs(rows) do
    local z = z0 + (i - 1) * step
    _G["dec" .. i] = function(_, _, alt) adjust(i, -(alt and row.step or 1)) end
    _G["inc" .. i] = function(_, _, alt) adjust(i,  (alt and row.step or 1)) end
    self.createButton({click_function = "noop", function_owner = self,
      label = row.label, position = bpos(-0.62, z), scale = BSCALE,
      width = W(2.0), height = W(0.36), font_size = W(0.155),
      color = {0.25, 0.25, 0.3}, font_color = {1, 1, 1}})
    self.createButton({click_function = "dec" .. i, function_owner = self,
      label = "-", position = bpos(0.62, z), scale = BSCALE,
      width = W(0.34), height = W(0.34), font_size = W(0.2),
      tooltip = "Right-click: -" .. row.step})
    row.valueBtn = #self.getButtons()
    self.createButton({click_function = "noop", function_owner = self,
      label = getVal(row) .. "/" .. row.max, position = bpos(1.1, z), scale = BSCALE,
      width = W(0.62), height = W(0.34), font_size = W(0.15),
      color = {0.95, 0.95, 0.95}})
    self.createButton({click_function = "inc" .. i, function_owner = self,
      label = "+", position = bpos(1.56, z), scale = BSCALE,
      width = W(0.34), height = W(0.34), font_size = W(0.2),
      tooltip = "Right-click: +" .. row.step})
  end
end

function noop() end

function adjust(i, d)
  local row = rows[i]
  local v = getVal(row) + d
  if v < 0 then v = 0 end
  if (row.kind == "ammo" or row.kind == "hp") and v > row.max then v = row.max end
  if row.kind == "hp" then setHP(v)
  elseif row.kind == "heat" then setHeat(v)
  else state.ammo[row.key] = v end
  self.editButton({index = row.valueBtn, label = v .. "/" .. row.max})
  updateMini()
end

-- Nudge a counter from the linked model's context menu.
function nudge(kind, d)
  for i, row in ipairs(rows) do
    if row.kind == kind then adjust(i, d); return end
  end
end

-- "Always round up": half of 42 HP is 21, a quarter of 42 is 11.
local function ceilDiv(a, b) return math.ceil(a / b) end

function setHP(v)
  local name = self.getName()
  state.hp = v
  local halfAt, quarterAt = ceilDiv(sheet.stats.hp, 2), ceilDiv(sheet.stats.hp, 4)
  if v > 0 and state.dead then state.dead = false; refreshDeadButton() end
  if not state.half and v <= halfAt and v > 0 then
    state.half = true
    broadcastToAll(name .. " reached 1/2 HP (" .. halfAt .. ") — roll on the threshold table.", {1, 0.75, 0.3})
  end
  if not state.quarter and v <= quarterAt and v > 0 then
    state.quarter = true
    broadcastToAll(name .. " reached 1/4 HP (" .. quarterAt .. ") — roll on the threshold table.", {1, 0.6, 0.2})
  end
  if v == 0 then
    state.dead = true
    refreshDeadButton()
    local msg = name .. " is DESTROYED — remove it from the map."
    if state.hot then msg = msg .. " It was overheating: it DETONATES (small area, dmg = heat over capacity)." end
    broadcastToAll(msg, {1, 0.35, 0.35})
  end
  applyTint()
end

function setHeat(v)
  local name, cap = self.getName(), sheet.stats.heatCap
  state.heat = v
  if not state.hot and v > cap then
    state.hot = true
    broadcastToAll(name .. " is OVERHEATING (" .. v .. "/" .. cap ..
      ") — roll on the threshold table; takes " .. (v - cap) .. " dmg at the end of its turn.", {1, 0.45, 0.3})
  elseif state.hot and v <= cap then
    state.hot = false
    broadcastToAll(name .. " is no longer overheating — its overheat threshold effect ends.", {0.6, 0.9, 0.6})
  end
  applyTint()
end

function toggleDead()
  state.dead = not state.dead
  refreshDeadButton()
  applyTint()
  updateMini()
  broadcastToAll(self.getName() .. (state.dead
    and " marked DESTROYED — it makes a partial order card each round."
    or  " is back in play."), {1, 0.75, 0.3})
end

function refreshDeadButton()
  self.editButton({index = 0, label = state.dead and "DEAD" or "alive",
                   color = state.dead and {0.5, 0.1, 0.1} or {0.2, 0.4, 0.2}})
end

function applyTint()
  if state.dead then self.setColorTint(DEAD_TINT)
  elseif state.hot then self.setColorTint(HOT_TINT)
  else self.setColorTint(BASE_TINT) end
  ensureFx()
end

-- ---------------- linked-model effects ----------------
-- Overheating: the mini's highlight pulses between deep and bright red.
-- Destroyed: animated electrical sparks (vector lines) crackle over it.
local fxTimer, fxPhase = nil, 0

function ensureFx()
  local need = state ~= nil and (state.hot or state.dead) and state.link ~= nil
  if need and fxTimer == nil then
    fxTimer = Wait.time(fxTick, 0.25, -1)
  elseif not need and fxTimer ~= nil then
    Wait.stop(fxTimer)
    fxTimer = nil
    local mini = linkedMini()
    if mini then mini.highlightOff(); mini.setVectorLines({}) end
  end
end

function fxTick()
  local mini = linkedMini()
  if mini == nil then
    if fxTimer then Wait.stop(fxTimer); fxTimer = nil end
    return
  end
  fxPhase = fxPhase + 0.25
  if state.dead then
    mini.highlightOff()
    mini.setVectorLines(sparkLines(mini))
  elseif state.hot then
    mini.setVectorLines({})
    local k = 0.5 + 0.5 * math.sin(fxPhase * 3.5)
    mini.highlightOn({0.45 + 0.55 * k, 0.08 + 0.3 * k, 0.05})
  end
end

-- Random jagged yellow/orange arcs in the model's local space, sized from
-- its bounds; redrawn every tick so they flicker like shorting electronics.
function sparkLines(mini)
  local sc = mini.getScale()
  local b = mini.getBoundsNormalized()
  local h = math.max(0.3, b.size.y / sc.y)          -- local height
  local r = math.max(0.2, (b.size.x / sc.x) * 0.45) -- local radius
  local lines = {}
  for i = 1, 3 + math.random(2) do
    local a = math.random() * 6.283
    local x, z = math.cos(a) * r, math.sin(a) * r
    local y = h * (0.25 + math.random() * 0.65)
    local pts = { {x, y, z} }
    for j = 1, 2 do
      x = x + (math.random() - 0.5) * r
      y = y + (math.random() - 0.35) * h * 0.3
      z = z + (math.random() - 0.5) * r
      table.insert(pts, {x, y, z})
    end
    table.insert(lines, {
      points = pts,
      color = math.random() < 0.5 and {1, 0.92, 0.45} or {1, 0.6, 0.2},
      thickness = 0.035,
    })
  end
  return lines
end

-- ---------------- model linking ----------------
function linkedMini()
  if state == nil or state.link == nil then return nil end
  return getObjectFromGUID(state.link)
end

function linkClicked(_, playerColor)
  if state.link then unlink(); return end
  -- shortcut: if the player already has a model selected, link it now
  local p = Player[playerColor]
  if p ~= nil then
    for _, o in ipairs(p.getSelectedObjects() or {}) do
      if o ~= self and not o.hasTag("BS_MECH") then
        completeLink({guid = o.getGUID()})
        return
      end
    end
  end
  Global.call("bsRequestLink", {tile = self, color = playerColor})
end

-- called by Global when the player picks a model up (link flow)
function completeLink(p)
  state.link = p.guid
  applyLink(false)
end

function applyLink(silent)
  local mini = linkedMini()
  if mini == nil then
    state.link = nil
    refreshLinkButton()
    return
  end
  mini.setDescription(self.getDescription())
  mini.addTag("BS_LINKED")
  mini.clearContextMenu()
  mini.addContextMenuItem("-1 HP",   function() nudge("hp", -1) end, true)
  mini.addContextMenuItem("+1 HP",   function() nudge("hp", 1) end, true)
  mini.addContextMenuItem("+1 Heat", function() nudge("heat", 1) end, true)
  mini.addContextMenuItem("-1 Heat", function() nudge("heat", -1) end, true)
  mini.addContextMenuItem("Cooling (-" .. (sheet.stats.cooling or 2) .. ")",
    function() nudge("heat", -(sheet.stats.cooling or 2)) end)
  mini.addContextMenuItem("Unlink sheet", function() unlink() end)
  refreshLinkButton()
  updateMini()
  applyTint()
  if not silent then
    broadcastToAll(sheet.name .. " linked to a model — hover the model for its sheet; right-click it for counters.", {0.8, 0.9, 1})
  end
end

function unlink()
  local mini = linkedMini()
  if mini then
    mini.clearContextMenu()
    mini.removeTag("BS_LINKED")
    mini.highlightOff()
    mini.setVectorLines({})
  end
  state.link = nil
  refreshLinkButton()
  broadcastToAll(sheet.name .. " unlinked from its model.", {0.8, 0.9, 1})
end

function refreshLinkButton()
  self.editButton({index = LINK_BTN, label = state.link and "Unlink" or "Link"})
end

-- live name on the mini: current HP/heat at a glance
function updateMini()
  local mini = linkedMini()
  if mini == nil then return end
  local nm
  if state.dead then
    nm = "[DESTROYED] " .. sheet.name
  else
    nm = sheet.name .. " [" .. (sheet.wclass or "?") .. "] — " ..
         state.hp .. "/" .. sheet.stats.hp .. " HP, " ..
         state.heat .. "/" .. sheet.stats.heatCap .. " heat"
  end
  mini.setName(nm)
end

function pingMini()
  local mini = linkedMini()
  if mini == nil then return end
  mini.highlightOn({0.3, 0.7, 1}, 3)
end
]==]
