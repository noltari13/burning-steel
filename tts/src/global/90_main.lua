-- ==================================================================
-- 90_main — entry point + Global persistence (area templates)
-- ==================================================================
function onLoad(saved)
  math.randomseed(os.time())
  if saved ~= nil and saved ~= "" then
    local ok, st = pcall(function() return JSON.decode(saved) end)
    if ok and type(st) == "table" and type(st.templates) == "table" then
      TEMPLATES_LIVE = st.templates
      renderTemplates()
    end
  end
  registerTemplateHotkeys()
  print("Burning Steel mod loaded (assets " .. ASSET_VERSION .. "). " ..
        "Toolbar: Import Warband / Round Setup / templates / Attack Roller. " ..
        "Bind template keys in Options > Game Keys.")
end

function onSave()
  return JSON.encode({ templates = TEMPLATES_LIVE })
end
