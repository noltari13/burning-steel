-- ==================================================================
-- 70_refs — spawn reference material: turn quick-ref card, rules PDF
-- ==================================================================
RULES_PDF_OVERRIDE = nil   -- update_save.py --local-pdf sets a file:/// URL

function rulesPdfUrl()
  return RULES_PDF_OVERRIDE or (ASSET_BASE .. "/rules.pdf")
end

local function spawnPosFor(player)
  local p = player.getPointerPosition and player.getPointerPosition()
  if p then return { p.x, (p.y or 1) + 2, p.z } end
  return { 0, 3, 0 }
end

function uiSpawnTurnRef(player)
  local card = spawnObject({
    type = "CardCustom",
    position = spawnPosFor(player),
    rotation = { 0, 180, 0 },
    scale = { 1.6, 1, 1.6 },
    sound = false,
    callback_function = function(o)
      o.setName("Turn quick reference")
      o.setDescription("2 AP + 1 reaction: attacks, movement, other actions, reactions.")
    end,
  })
  card.setCustomObject({
    face = ASSET_BASE .. "/ref_actions.png",
    back = ASSET_BASE .. "/card_back.png",
  })
end

function uiSpawnRules(player)
  local pdf = spawnObject({
    type = "Custom_PDF",
    position = spawnPosFor(player),
    rotation = { 0, 180, 0 },
    sound = false,
    callback_function = function(o)
      o.setName("Burning Steel — full rules")
      o.setDescription("Use the arrows on the object to turn pages. Alt-zoom to read.")
    end,
  })
  pdf.setCustomObject({ pdf = rulesPdfUrl() })
end
