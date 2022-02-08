local origExecOnExec = MissionScriptElement.execute_on_executed
function MissionScriptElement:execute_on_executed(params)
  local heist = managers.job:current_level_id()

  if heist == "rat" or heist == "alex_1" then
    if self:editor_name() == "reChance" or self:editor_name() == "3IngredientsAdded" then
      self._values.on_executed[1].delay = 0.1
    end
  elseif heist == "mia_1" or heist == "crojob2" then
    if self:editor_name() == "timer_to_next" then
      for k in pairs(self._values.on_executed) do
        self._values.on_executed[k].delay = 0.1
      end
    end
  end

  origExecOnExec(self, params)
end