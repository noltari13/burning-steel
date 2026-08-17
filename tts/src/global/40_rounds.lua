-- ==================================================================
-- 40_rounds — Round Setup: deal order / partial / pass cards
-- Card sources are three infinite bags on the table, tagged
-- BS_BAG_ORDER / BS_BAG_PARTIAL / BS_BAG_PASS (set up once; see README).
-- ==================================================================
ROUND_NUMBER = 0

function uiRoundSetup(player)
  local sides = {}   -- color -> {orders = n, partials = n}
  for _, o in ipairs(getObjectsWithTag(TAG_MECH)) do
    for _, tag in ipairs(o.getTags()) do
      local color = tag:match("^BS_(%a+)$")
      if color and color ~= "MECH" and color ~= "OVERDRIVE" and color ~= "TEMPLATE" then
        sides[color] = sides[color] or { orders = 0, partials = 0 }
        if bsTileDead(o) then
          -- A destroyed mech makes a partial order card; a destroyed
          -- Overdrive Engine mech makes no order cards at all.
          if not o.hasTag(TAG_OVERDRIVE) then
            sides[color].partials = sides[color].partials + 1
          end
        else
          sides[color].orders = sides[color].orders + 1
            + (o.hasTag(TAG_OVERDRIVE) and 1 or 0)
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
    totals[c] = s.orders + s.partials
    dealFromBag(TAG_BAG_ORDER, s.orders, c)
    dealFromBag(TAG_BAG_PARTIAL, s.partials, c)
    bsInfo(c .. ": " .. s.orders .. " order" .. (s.orders == 1 and "" or "s")
      .. (s.partials > 0 and (" + " .. s.partials .. " partial") or ""))
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
function dealFromBag(bagTag, count, color)
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
  local ht = Player[color].getHandTransform()
  for i = 1, count do
    local pos = ht and {
      x = ht.position.x + ht.right.x * (i - 1) * 0.3,
      y = ht.position.y + 0.5 + i * 0.3,
      z = ht.position.z + ht.right.z * (i - 1) * 0.3,
    } or { x = 0, y = 3 + i, z = 0 }
    bag.takeObject({ position = pos, rotation = ht and ht.rotation or { 0, 180, 0 }, smooth = false })
  end
end
