SCD = { }
SCD.Path = ModPath
-- SCD.Path = ModPath .. "SkipCookingDelay/"

local canPrint = false

local Ingredients =
{
  "acid",
  "caustic_soda",
  "hydrogen_chloride"
}

local function IsIngredient(ingred)
  return table.contains(Ingredients, ingred)
end

function SCD:GetElement(desiredElement)
  for _, s in pairs(managers.mission:scripts()) do
    for _, element in pairs(s:elements()) do
      if element._editor_name == desiredElement then
        return element
      end
    end
  end

  return nil
end

function SCD:FindElementInTableByName(tbl, name)
  local desiredElem = self:GetElement(name)

  for i, elem in ipairs(tbl) do
    if elem.id == desiredElem._id then
      return i, elem
    end
  end

  return nil
end

function SCD:ExecuteElements(elements, disableAfterExec, enableAfterExec)
  for _, name in ipairs(elements) do
    local escapeNest = false

    for _, script in pairs(managers.mission:scripts()) do
      for _, element in pairs(script:elements()) do
        if element._editor_name == name then
          element:on_executed(managers.network:session():local_peer())

          local changeToState = nil

          if disableAfterExec and not enableAfterExec then
            changeToState = false
          elseif enableAfterExec and not disableAfterExec then
            changeToState = true
          end

          if changeToState ~= nil then
            element:set_enabled(changeToState)
          end

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

local ReplacedStats =
{
  mCook = nil,
  startCooking = nil,
  disableLab = nil
}

function SCD:ConfirmStats()
  if not ReplacedStats.mCook or not ReplacedStats.startCooking then
    return false end

  return
  table.size(self:GetElement("disable_interaction_methlab")) == table.size(ReplacedStats.disableLab._values.trigger_list)
  and
  (self:GetElement("met_cooks")._values.base_delay == ReplacedStats.startCooking._values.base_delay)
  and
  (self:GetElement("methCook")._values.chance == ReplacedStats.mCook._values.chance)
end

function SCD:ReplaceStats()
  local function CheckValid(invalidStats)
    return invalidStats == true
  end

  local mCook = self:GetElement("methCook")
  if mCook ~= nil then
    while CheckValid(mCook._values.chance ~= 100 or mCook._chance ~= 100) do
      mCook._values.delay_rand = nil
      mCook._values.delay = 0

      mCook._values.chance = 100
      mCook:chance_operation_set_chance(100)
    end
    ReplacedStats.mCook = mCook
  end

  local startCooking = self:GetElement("met_cooks")
  if startCooking ~= nil then
    while CheckValid(startCooking._values.base_delay ~= 0) do
      local index = self:FindElementInTableByName(startCooking._values.on_executed, "startCooking")

      if index then
        startCooking._values.on_executed[index].delay = 0
      end

      startCooking._values.base_delay = 0
    end
    ReplacedStats.startCooking = startCooking
  end

  local disableLab = self:GetElement("disable_interaction_methlab")
  if disableLab ~= nil then
    while CheckValid(table.size(disableLab._values.trigger_list) ~= 0) do
      disableLab:set_enabled(false)
      disableLab._values.trigger_list = { }
    end
    ReplacedStats.disableLab = disableLab
  end
end

local origExec = MissionScriptElement.on_executed
function MissionScriptElement:on_executed(inst, alt, skipExec)
  if not SCD:ConfirmStats() and Utils:IsInHeist() then
    SCD:ReplaceStats()
  end

  if canPrint then
    PrintTableDeep(self, 3)
  end

  return origExec(self, inst, alt, skipExec)
end

-- local origInteract = UseInteractionExt.interact
-- function UseInteractionExt:interact(player)
--   if not LuaNetworking:IsHost() or not IsIngredient(self._tweak_data.special_equipment) then
--     return origInteract(self, player) end
-- end

local eee = ChatManager.receive_message_by_peer
function ChatManager:receive_message_by_peer(_, pee, mess)
  if pee ~= managers.network:session():local_peer() then
    return eee(self, _, pee, mess)
  end

  local me = mess:lower()

  if me == "p" then
    canPrint = not canPrint

    managers.chat:send_message(1, nil, "now " .. tostring(canPrint))
  end

  return eee(self, _, pee, mess)
end