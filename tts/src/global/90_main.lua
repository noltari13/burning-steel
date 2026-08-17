-- ==================================================================
-- 90_main — entry point
-- ==================================================================
function onLoad()
  math.randomseed(os.time())
  print("Burning Steel mod loaded (assets " .. ASSET_VERSION .. "). " ..
        "Toolbar: Import Warband / Round Setup / templates / Attack Roller.")
end
