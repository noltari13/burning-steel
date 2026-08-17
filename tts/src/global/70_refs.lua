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

-- spawnObjectData (not spawnObject + setCustomObject): the two-step form
-- can race object init and pop TTS's blank "load custom object" dialog.
local function refTransform(pos, scale)
  return { posX = pos[1], posY = pos[2], posZ = pos[3],
           rotX = 0, rotY = 180, rotZ = 0,
           scaleX = scale, scaleY = 1, scaleZ = scale }
end

function uiSpawnTurnRef(player)
  spawnObjectData({
    data = {
      Name = "CardCustom",
      Transform = refTransform(spawnPosFor(player), 1.6),
      Nickname = "Turn quick reference",
      Description = "2 AP + 1 reaction: attacks, movement, other actions, reactions.",
      CardID = 420100,
      CustomDeck = { ["4201"] = {
        FaceURL = ASSET_BASE .. "/ref_actions.png",
        BackURL = ASSET_BASE .. "/card_back.png",
        NumWidth = 1, NumHeight = 1,
        BackIsHidden = true, UniqueBack = false,
      } },
    },
  })
end

function uiSpawnRules(player)
  spawnObjectData({
    data = {
      Name = "Custom_PDF",
      Transform = refTransform(spawnPosFor(player), 1),
      Nickname = "Burning Steel — full rules",
      Description = "Use the arrows on the object to turn pages. Alt-zoom to read.",
      CustomPDF = {
        PDFUrl = rulesPdfUrl(),
        PDFPassword = "",
        PDFPage = 0,
        PDFPageOffset = 0,
      },
    },
  })
end
