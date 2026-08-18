-- ==================================================================
-- 40_rounds — Round Setup: deal order / partial / pass cards
-- Card sources are three infinite bags on the table, tagged
-- BS_BAG_ORDER / BS_BAG_PARTIAL / BS_BAG_PASS (set up once; see README).
-- ==================================================================
ROUND_NUMBER = 0

-- The tile's mech name, read from its GM Notes snapshot.
local function tileMechName(tile)
  local ok, s = pcall(function() return JSON.decode(tile.getGMNotes()) end)
  if ok and type(s) == "table" and s.name then return s.name end
  return tile.getName()
end

function uiRoundSetup(player)
  local sides = {}   -- color -> {orders = {name...}, partials = {name...}}
  for _, o in ipairs(getObjectsWithTag(TAG_MECH)) do
    for _, tag in ipairs(o.getTags()) do
      local color = tag:match("^BS_(%a+)$")
      if color and color ~= "MECH" and color ~= "OVERDRIVE" and color ~= "TEMPLATE" and color ~= "LINKED" then
        sides[color] = sides[color] or { orders = {}, partials = {} }
        local name = tileMechName(o)
        if bsTileDead(o) then
          -- A destroyed mech makes a partial order card; a destroyed
          -- Overdrive Engine mech makes no order cards at all.
          if not o.hasTag(TAG_OVERDRIVE) then
            table.insert(sides[color].partials, name)
          end
        else
          table.insert(sides[color].orders, name)
          if o.hasTag(TAG_OVERDRIVE) then
            table.insert(sides[color].orders, name .. " (Overdrive)")
          end
        end
      end
    end
  end

  local colors = {}
  for c in pairs(sides) do table.insert(colors, c) end
  table.sort(colors)
  if #colors == 0 then
    bsError("No mechs on the table — import a warband first.")
    return
  end

  ROUND_NUMBER = ROUND_NUMBER + 1
  bsInfo("— Round " .. ROUND_NUMBER .. " —")
  local totals = {}
  for _, c in ipairs(colors) do
    local s = sides[c]
    totals[c] = #s.orders + #s.partials
    local orderLabels = {}
    for _, n in ipairs(s.orders) do
      table.insert(orderLabels, "Order — " .. n)
    end
    local partialLabels = {}
    for _, n in ipairs(s.partials) do
      table.insert(partialLabels, "Partial order (from " .. n .. ")")
    end
    dealFromBag(TAG_BAG_ORDER, #s.orders, c, orderLabels)
    dealFromBag(TAG_BAG_PARTIAL, #s.partials, c, partialLabels)
    bsInfo(c .. ": " .. #s.orders .. " order" .. (#s.orders == 1 and "" or "s")
      .. (#s.partials > 0 and (" + " .. #s.partials .. " partial") or ""))
  end

  -- Pass cards: only defined for a two-sided game.
  if #colors == 2 then
    local a, b = colors[1], colors[2]
    local diff = totals[a] - totals[b]
    if diff ~= 0 then
      local fewer = diff < 0 and a or b
      dealFromBag(TAG_BAG_PASS, math.abs(diff), fewer)
      bsInfo(fewer .. " gets " .. math.abs(diff) .. " pass card" .. (math.abs(diff) == 1 and "" or "s") .. ".")
    end
  elseif #colors > 2 then
    bsWarn("More than two sides — deal pass cards by hand (the rules define them for two players).")
  end
  bsInfo("Play cards onto the timeline in order; all cards must be used this round.")
end

local warnedNoBags = false
-- labels: optional per-card names (e.g. "Order — Squall"). A mech order
-- card may only be used by its own mech, so naming the card enforces at
-- a glance what the rules already require.
function dealFromBag(bagTag, count, color, labels)
  if count <= 0 then return end
  local bag = getObjectsWithTag(bagTag)[1]
  if bag == nil then
    if not warnedNoBags then
      warnedNoBags = true
      bsWarn("Card bags not found — create three infinite bags of order/partial/pass cards and tag them "
        .. TAG_BAG_ORDER .. ", " .. TAG_BAG_PARTIAL .. ", " .. TAG_BAG_PASS .. " (see tts/README.md).")
    end
    return
  end
  -- deal() puts the card in the hand with the correct facing; dropping it
  -- at the hand position by rotation guesswork faced cards away from players.
  local above = bag.getPosition()
  for i = 1, count do
    local label = labels and labels[i]
    bag.takeObject({
      position = { above.x, above.y + 1 + i * 0.4, above.z },
      smooth = false,
      callback_function = function(o)
        if label then o.setName(label) end
        o.deal(1, color)
      end,
    })
  end
end
