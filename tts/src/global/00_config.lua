-- ==================================================================
-- 00_config — asset URLs, hex geometry, shared constants
-- ==================================================================
-- TTS caches images by URL forever: never overwrite a published PNG,
-- bump the version folder (v1 -> v2) and ASSET_VERSION together.
ASSET_VERSION = "v1"
ASSET_BASE = "https://noltari13.github.io/burning-steel/tts/assets/png/" .. ASSET_VERSION

-- Grid geometry. GRID_X must equal Options > Grid > X Size in the save.
-- Flat-top hexes ("Hex (Horizontal)" in TTS options).
GRID_X = 2

-- Area templates (nested rings per the Area Sizes rules).
-- hexesAcross = widest span of the cluster in hexes; a Custom_Tile is 2
-- world units wide at scale 1, so scale = hexesAcross * GRID_X / 2.
TEMPLATES = {
  { key = "targeted", label = "Target",  hexesAcross = 1 },
  { key = "small",    label = "Small",   hexesAcross = 3 },
  { key = "medium",   label = "Medium",  hexesAcross = 5 },
  { key = "large",    label = "Large",   hexesAcross = 7 },
}

-- Object tags
TAG_MECH      = "BS_MECH"
TAG_OVERDRIVE = "BS_OVERDRIVE"
TAG_TEMPLATE  = "BS_TEMPLATE"
TAG_BAG_ORDER   = "BS_BAG_ORDER"    -- infinite bag holding one Order card
TAG_BAG_PARTIAL = "BS_BAG_PARTIAL"  -- infinite bag holding one Partial Order card
TAG_BAG_PASS    = "BS_BAG_PASS"     -- infinite bag holding one Pass card

-- Stat tile footprint (world units); the tile script must use the same values.
TILE_SX, TILE_SY, TILE_SZ = 3.4, 0.2, 4.4
