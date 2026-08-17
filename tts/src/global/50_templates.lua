-- ==================================================================
-- 50_templates — area templates as vector-line hex outlines.
-- No physical object: rings are drawn on the board at the hex under
-- the player's pointer, so they never cover models or hide terrain.
-- T/S/M/L places one; Clear removes your latest (right-click: all).
-- Ring colors follow the Area Sizes rules (red / light red / orange /
-- yellow). Templates persist in the save (see 90_main onSave/onLoad).
-- ==================================================================
TEMPLATE_RADII = { targeted = 0, small = 1, medium = 2, large = 3 }
RING_COLORS = {
  [0] = {0.92, 0.28, 0.30},
  [1] = {0.96, 0.60, 0.62},
  [2] = {0.96, 0.65, 0.14},
  [3] = {0.97, 0.82, 0.33},
}
-- If outlines sit consistently off the hexes, tune these to your grid.
GRID_OFFSET_X, GRID_OFFSET_Z = 0, 0

TEMPLATES_LIVE = {}   -- {owner, key, lines = {...}} in placement order

-- Flat-top hex geometry; GRID_X is the corner-to-corner hex width.
local function hexS() return GRID_X / 2 end

local function axialToWorld(q, r)
  local s = hexS()
  return GRID_OFFSET_X + 1.5 * s * q,
         GRID_OFFSET_Z + math.sqrt(3) * s * (r + q / 2)
end

local function worldToAxial(x, z)
  local s = hexS()
  local qf = (x - GRID_OFFSET_X) / (1.5 * s)
  local rf = (z - GRID_OFFSET_Z) / (math.sqrt(3) * s) - qf / 2
  -- cube rounding
  local xf, zf = qf, rf
  local yf = -xf - zf
  local rx, ry, rz = math.floor(xf + 0.5), math.floor(yf + 0.5), math.floor(zf + 0.5)
  local dx, dy, dz = math.abs(rx - xf), math.abs(ry - yf), math.abs(rz - zf)
  if dx > dy and dx > dz then rx = -ry - rz
  elseif dy > dz then ry = -rx - rz
  else rz = -rx - ry end
  return rx, rz
end

local function hexOutline(q, r, y, ring)
  local cx, cz = axialToWorld(q, r)
  local s = hexS() * 0.94          -- slight inset so neighbours don't overlap
  local pts = {}
  for i = 0, 6 do
    local a = math.pi / 3 * i      -- flat-top: first corner at angle 0
    table.insert(pts, {cx + s * math.cos(a), y, cz + s * math.sin(a)})
  end
  return {
    points = pts,
    color = RING_COLORS[math.min(ring, 3)],
    thickness = ring == 0 and 0.12 or 0.07,
  }
end

function placeTemplate(color, key, pos)
  local radius = TEMPLATE_RADII[key]
  if radius == nil or pos == nil then return end
  local cq, cr = worldToAxial(pos.x, pos.z)
  local y = (pos.y or 1) + 0.08
  local lines = {}
  for dq = -radius, radius do
    for dr = math.max(-radius, -dq - radius), math.min(radius, -dq + radius) do
      local ring = (math.abs(dq) + math.abs(dr) + math.abs(-dq - dr)) / 2
      table.insert(lines, hexOutline(cq + dq, cr + dr, y, ring))
    end
  end
  table.insert(TEMPLATES_LIVE, {owner = color, key = key, lines = lines})
  renderTemplates()
end

function clearLatestTemplate(color)
  for i = #TEMPLATES_LIVE, 1, -1 do
    if TEMPLATES_LIVE[i].owner == color then
      table.remove(TEMPLATES_LIVE, i)
      renderTemplates()
      return
    end
  end
end

-- Toolbar path (pointer sits on the UI when clicking, so the hex under it
-- is a guess — hotkeys below are the reliable way to place).
function uiTemplate(player, _, id)
  local p = player.getPointerPosition and player.getPointerPosition()
  placeTemplate(player.color, id:gsub("^tpl_", ""), p or {x = 0, y = 1, z = 0})
end

function uiTemplateClear(player, mouseButton)
  if mouseButton == "-2" then          -- right-click: clear everything
    TEMPLATES_LIVE = {}
    renderTemplates()
  else                                 -- left-click: your most recent
    clearLatestTemplate(player.color)
  end
end

-- Scripted hotkeys: bind keys in Options > Game Keys. The callback hands
-- us the pointer's world position, so you place while hovering the hex.
function registerTemplateHotkeys()
  local order = {"targeted", "small", "medium", "large"}
  local labels = {targeted = "Targeted hex", small = "Small area",
                  medium = "Medium area", large = "Large area"}
  for _, key in ipairs(order) do
    addHotkey("Template: " .. labels[key], function(color, _, pos, isKeyUp)
      if not isKeyUp then placeTemplate(color, key, pos) end
    end)
  end
  addHotkey("Template: clear my latest", function(color, _, _, isKeyUp)
    if not isKeyUp then clearLatestTemplate(color) end
  end)
end

function renderTemplates()
  local all = {}
  for _, t in ipairs(TEMPLATES_LIVE) do
    for _, ln in ipairs(t.lines) do table.insert(all, ln) end
  end
  Global.setVectorLines(all)
end
