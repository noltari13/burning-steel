-- ==================================================================
-- 35_link — model-linking handshake for stat tiles.
-- The tile can't see pick-up events, so it registers a pending link
-- here; the next model the player picks up completes it.
-- ==================================================================
PENDING_LINK = {}   -- player color -> stat tile awaiting a model

function bsRequestLink(p)
  if PENDING_LINK[p.color] == p.tile then
    PENDING_LINK[p.color] = nil
    bsInfo(p.color .. ": link cancelled.")
    return
  end
  PENDING_LINK[p.color] = p.tile
  bsInfo(p.color .. ": pick up the miniature to link to " .. p.tile.getName()
    .. " (press Link again to cancel).")
end

-- Switching a multi-state model (right-click > States / number keys)
-- replaces the object and may change its GUID — re-link its tile so the
-- sheet, name, menus and effects carry over to the new appearance.
function onObjectStateChange(obj, oldGuid)
  for _, tile in ipairs(getObjectsWithTag(TAG_MECH)) do
    local ok, linked = pcall(function() return tile.call("getLinkGuid") end)
    if ok and linked == oldGuid then
      tile.call("completeLink", { guid = obj.getGUID(), silent = true })
      return
    end
  end
end

function onObjectPickUp(color, obj)
  local tile = PENDING_LINK[color]
  if tile == nil then return end
  if obj == tile then return end                -- moving the tile itself
  if obj.hasTag(TAG_MECH) then
    bsWarn("That's a stat tile — pick up the miniature instead.")
    return
  end
  PENDING_LINK[color] = nil
  tile.call("completeLink", { guid = obj.getGUID() })
end
