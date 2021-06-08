local Ingredients =
{
  "muriatic_acid",
  "acid",
  "caustic_soda",
  "hydrogen_chloride"
}

local function IsIngredient(ingred)
  return table.contains(Ingredients, ingred)
end

local function ExecuteElements(elements)
  for _, name in ipairs(elements) do
    local escapeNest = false

    for _, script in pairs(managers.mission:scripts()) do
      for _, element in pairs(script:elements()) do
        if element._editor_name == name then
          element:on_executed()
          escapeNest = true

          break
        end
      end

      if escapeNest then
        break
      end
    end
  end
end

local origInteract = UseInteractionExt.interact
function UseInteractionExt:interact(player)
  local result = origInteract(self, player)

  if not LuaNetworking:IsHost() or not IsIngredient(self._tweak_data.special_equipment) then
    return result end

  ExecuteElements({ "needIngrediens" })

  return result
end