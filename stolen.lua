
----------------------------------------------------
-- ICONS
----------------------------------------------------
AIB.icons["Stolen"]         = "|t24:24:esoui/art/inventory/gamepad/gp_inventory_icon_stolenitem.dds|t"
AIB.icons["StolenWarning"]  = "|t24:24:esoui/art/inventory/gamepad/gp_inventory_icon_stolenitem.dds|t"
AIB.icons["StolenCritical"] = "|t24:24:esoui/art/inventory/gamepad/gp_inventory_icon_stolenitem.dds|t"

----------------------------------------------------
-- SAVED VARS
----------------------------------------------------
AIB.defaults["Stolen"] = {
  on = true,
}

----------------------------------------------------
-- METHODS CALLED FROM PARENT
----------------------------------------------------
AIB.plugins["Stolen"] = {

  ------------------------------------------------
  -- PARENT METHOD: Initialize
  ------------------------------------------------
  Initialize = function()
    AIB.plugins.Stolen.UpdateStolen()
  end,

  ------------------------------------------------
  -- PARENT METHOD: RegisterEvents
  ------------------------------------------------
  RegisterEvents = function()
    if (AIB.saved.account.Stolen.on) then
      EVENT_MANAGER:RegisterForEvent("AIB_Stolen", EVENT_LOOT_RECEIVED, AIB.plugins.Stolen.OnNeedStolenUpdate)
      EVENT_MANAGER:RegisterForEvent("AIB_Stolen", EVENT_JUSTICE_FENCE_UPDATE, AIB.plugins.Stolen.OnNeedStolenUpdate)
      EVENT_MANAGER:RegisterForEvent("AIB_Stolen", EVENT_INVENTORY_ITEM_DESTROYED, AIB.plugins.Stolen.OnNeedStolenUpdate)
      EVENT_MANAGER:RegisterForEvent("AIB_Stolen", EVENT_END_CRAFTING_STATION_INTERACT, AIB.plugins.Stolen.OnNeedStolenUpdate)
    else
      EVENT_MANAGER:UnregisterForEvent("AIB_Stolen", EVENT_LOOT_RECEIVED)
      EVENT_MANAGER:UnregisterForEvent("AIB_Stolen", EVENT_JUSTICE_FENCE_UPDATE)
      EVENT_MANAGER:UnregisterForEvent("AIB_Stolen", EVENT_INVENTORY_ITEM_DESTROYED)
      EVENT_MANAGER:UnregisterForEvent("AIB_Stolen", EVENT_END_CRAFTING_STATION_INTERACT)
    end
  end,

  ------------------------------------------------
  -- EVENT: OnNeedStolenUpdate
  ------------------------------------------------
  OnNeedStolenUpdate = function()
    AIB.plugins.Stolen.UpdateStolen()
  end,

  ------------------------------------------------
  -- METHOD: UpdateStolen
  ------------------------------------------------
  UpdateStolen = function()
    local snoozing = AIB.isSnoozing("Stolen")
    AIB.setLabel("Stolen","")

    if (AIB.saved.account.Stolen.on and not snoozing) then
      local header, value = "",""
      local stolenCount = 0

      -- get data
      local bag = SHARED_INVENTORY:GenerateFullSlotData(nil, BAG_BACKPACK)
      for _, data in pairs(bag) do
        if IsItemStolen(data.bagId, data.slotIndex) then
          stolenCount = stolenCount + GetSlotStackSize(data.bagId, data.slotIndex)
        end
      end

      -- set header
      header = AIB.setHeader("Stolen", false, true)

      -- set value
      value = AIB.setValue(stolenCount, false, true)

      -- set label
      if (stolenCount > 0) then
        AIB.setLabel("Stolen", header..value)
      end
    end
  end,
}

----------------------------------------------------
-- SETTINGS MENU
----------------------------------------------------
AIB.plugins.Stolen.Menu = {
  {
    type = "submenu",
    name = AIB.icons.Stolen..AIB.colors.blue.."Stolen|r",
    controls = {
      {
        type = "description",
        text = AIB.colors.orange.."Displays stolen item count|r",
      },
      {
        type = "checkbox",
        name = "Enabled",
        tooltip = "Enables this plugin when checked",
        getFunc = function() return AIB.saved.account.Stolen.on end,
        setFunc = function(newValue) AIB.saved.account.Stolen.on = newValue; AIB.plugins.Stolen.RegisterEvents(); AIB.plugins.Stolen.UpdateStolen() end,
        default = AIB.defaults.Stolen.on,
      }
    }
  }
}
