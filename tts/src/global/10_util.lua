-- ==================================================================
-- 10_util — chat helpers, misc
-- ==================================================================
function bsInfo(msg)  broadcastToAll(msg, {0.8, 0.9, 1}) end
function bsWarn(msg)  broadcastToAll(msg, {1, 0.75, 0.3}) end
function bsError(msg) broadcastToAll(msg, {1, 0.4, 0.4}) end

-- Strip UTF-8 BOM and smart quotes that break TTS's strict JSON decoder.
function bsCleanJson(s)
  if s == nil then return "" end
  s = s:gsub("^\239\187\191", "")                    -- BOM
  s = s:gsub("\226\128\156", "\""):gsub("\226\128\157", "\"") -- “ ”
  s = s:gsub("\226\128\152", "'"):gsub("\226\128\153", "'")   -- ‘ ’
  return s
end

function bsSeatedColors()
  local out = {}
  for _, p in ipairs(Player.getPlayers()) do
    if p.seated and p.color ~= "Grey" and p.color ~= "Black" then
      table.insert(out, p.color)
    end
  end
  return out
end

-- All live stat tiles, optionally filtered to one player's color tag.
function bsMechTiles(color)
  local out = {}
  for _, o in ipairs(getObjectsWithTag(TAG_MECH)) do
    if color == nil or o.hasTag("BS_" .. color) then table.insert(out, o) end
  end
  return out
end

-- Ask a stat tile whether its DEAD toggle is on (tile script exposes isDead).
function bsTileDead(tile)
  local ok, dead = pcall(function() return tile.call("isDead") end)
  return ok and dead == true
end
