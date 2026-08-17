-- ==================================================================
-- 60_attack — attack helper: roll shots vs Dv, apply the attack table
--   Miss: 3+ under (x0) | Chip: 1-2 under (x1/2, round up)
--   Hit: >= Dv (x1) | Crit 1/2/3: Av >= 2x/3x/4x Dv (x2/x3/x4)
-- ==================================================================
ATK = { shots = 1, acc = 0, dv = 3, dmg = 0 }

function onAttackInput(player, value, id)
  local n = tonumber(value)
  if n == nil then return end
  ATK[id:gsub("^atk_", "")] = math.floor(n)
end

function uiAttackOpen(player) UI.show("attackPanel") end
function uiAttackClose(player) UI.hide("attackPanel") end

local function classify(av, dv)
  if av >= 4 * dv then return "CRIT 3", 4
  elseif av >= 3 * dv then return "CRIT 2", 3
  elseif av >= 2 * dv then return "CRIT 1", 2
  elseif av >= dv then return "Hit", 1
  elseif av >= dv - 2 then return "Chip", 0.5
  else return "Miss", 0 end
end

function uiAttackRoll(player)
  local shots = math.max(1, math.min(20, ATK.shots or 1))
  local acc, dv, dmg = ATK.acc or 0, ATK.dv or 3, ATK.dmg or 0
  local total = 0
  broadcastToAll(player.color .. " attacks: " .. shots .. " shot" .. (shots == 1 and "" or "s")
    .. ", " .. (acc >= 0 and "+" or "") .. acc .. " to hit, vs Dv " .. dv
    .. (dmg > 0 and (", " .. dmg .. " dmg/shot") or ""), Color[player.color] or {1, 1, 1})
  for i = 1, shots do
    local roll = math.random(1, 10)
    local av = roll + acc
    local label, mult = classify(av, dv)
    local line = "  d10 " .. roll .. (acc ~= 0 and ((acc > 0 and " +" or " ") .. acc .. " = " .. av) or "")
      .. " vs " .. dv .. " -> " .. label
    if dmg > 0 then
      local d = mult == 0.5 and math.ceil(dmg / 2) or dmg * mult   -- always round up
      total = total + d
      line = line .. " (" .. d .. " dmg)"
    elseif mult ~= 1 then
      line = line .. " (x" .. (mult == 0.5 and "1/2" or mult) .. " dmg)"
    end
    broadcastToAll(line, mult == 0 and {0.6, 0.6, 0.6} or (mult >= 2 and {1, 0.85, 0.3} or {1, 1, 1}))
  end
  if dmg > 0 then
    broadcastToAll("  Total: " .. total .. " damage.", {0.8, 0.95, 1})
  end
end
