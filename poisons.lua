
-------------------------------------------------
-- ICONS
-------------------------------------------------
-- art\icons\crowncrate_poison_001.dds
-- art\icons\green_poison_vial.dds
-- esoui\art\actionbar\stateoverlay_poison.dds
-- esoui\art\tooltips\icon_poison.dds
AIB.icons["Poisons"]          = "|t22:22:esoui/art/tooltips/icon_poison.dds|t"
AIB.icons["PoisonsWarning"]   = "|t22:22:esoui/art/tooltips/icon_poison.dds|t"
AIB.icons["PoisonsCritical"]  = "|t22:22:esoui/art/tooltips/icon_poison.dds|t"


-------------------------------------------------
-- SAVED VARS
-------------------------------------------------
AIB.defaults["Poisons"] = {
  on          = false,
  alwaysOn    = false,
  warning     = 10,
  critical    = 5,
}


-------------------------------------------------
-- METHODS CALL FROM PARENT
-------------------------------------------------
AIB.plugins["Poisons"] = {

  -----------------------------------------------
  -- PARENT METHOD: Initialize
  -----------------------------------------------
  Initialize = function()
    if (AIB.saved.character.Poisons == nil) then
      AIB.saved.character.Poisons = AIB.defaults.Poisons
    end
    AIB.plugins.Poisons.UpdatePoisons()
  end,

  -----------------------------------------------
  -- PARENT METHOD: RegisterEvents
  -----------------------------------------------
  RegisterEvents = function()
    if (AIB.saved.character.Research.on) then
      -- setup
      EVENT_MANAGER:RegisterForEvent("AIB_Poisons", EVENT_PLAYER_ACTIVATED, AIB.plugins.Poisons.UpdatePoisons)
      -- poison proc'd
      EVENT_MANAGER:RegisterForEvent("AIB_Poisons", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, AIB.plugins.Poisons.OnSlotUpdate)
      -- weapons updated
      EVENT_MANAGER:RegisterForEvent("AIB_Poisons", EVENT_ACTIVE_WEAPON_PAIR_CHANGED, AIB.plugins.Poisons.OnWeaponChange)
      -- switched bars
      EVENT_MANAGER:RegisterForEvent("AIB_Poisons", EVENT_ACTION_SLOTS_FULL_UPDATE, AIB.plugins.Poisons.OnBarSwitch)
    else
      EVENT_MANAGER:UnregisterForEvent("AIB_Poisons", EVENT_PLAYER_ACTIVATED)
      EVENT_MANAGER:UnregisterForEvent("AIB_Poisons", EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
      EVENT_MANAGER:UnregisterForEvent("AIB_Poisons", EVENT_ACTIVE_WEAPON_PAIR_CHANGED)
      EVENT_MANAGER:UnregisterForEvent("AIB_Poisons", EVENT_ACTION_SLOTS_FULL_UPDATE)
    end
  end,

  -----------------------------------------------
  -- HELPER METHOD: GetStackSize
  -----------------------------------------------
  GetStackSize = function()
    local weaponPair = GetActiveWeaponPairInfo()
    local equipSlot, stackSize

    if (weaponPair == ACTIVE_WEAPON_PAIR_MAIN) then
      equipSlot = EQUIP_SLOT_MAIN_HAND
    else
      equipSlot = EQUIP_SLOT_BACKUP_MAIN
    end

    _, stackSize = GetItemPairedPoisonInfo(equipSlot)

    return stackSize
  end,

  -----------------------------------------------
  -- EVENT: UpdatePoisons
  -----------------------------------------------
  UpdatePoisons = function()
    local snoozing = AIB.isSnoozing("Poisons")
    AIB.setLabel("Poisons", "")

    if (AIB.saved.character.Poisons.on and not snoozing) then
      local header, value = "", ""
      local isWarning, isCritical = false, false
      local stackSize = AIB.plugins.Poisons.GetStackSize()

      if stackSize < AIB.saved.character.Poisons.warning then
        if stackSize <= AIB.saved.character.Poisons.critical then
          isCritical = true
        else
          isWarning = true
        end
      end

      -- set header
      header = AIB.setHeader("Poisons", isWarning, isCritical)
      -- set value
      value = AIB.setValue(stackSize, isWarning, isCritical)

      -- set label
      if ((not AIB.saved.character.Poisons.alwaysOn and (isWarning or isCritical))
        or (AIB.saved.character.Poisons.alwaysOn)) then
        AIB.setLabel("Poisons", header..value)
      end
    end
  end,

  -----------------------------------------------
  -- EVENT: OnSlotUpdate
  -----------------------------------------------
  OnSlotUpdate = function(eventCode, bagId, slotId, isNewItem, itemSoundCategory, inventoryUpdateReason, stackSizeChange)
    if bagId == 0 and stackSizeChange == -1 then
      AIB.plugins.Poisons.UpdatePoisons()
    end
  end,

  -----------------------------------------------
  -- EVENT: OnWeaponChange
  -----------------------------------------------
  OnWeaponChange = function(eventCode, activeWeaponPair, locked)
    local weaponPair = GetActiveWeaponPairInfo()

    if weaponPair == activeWeaponPair then
      AIB.plugins.Poisons.UpdatePoisons()
    end
  end,

  -----------------------------------------------
  -- EVENT: OnBarSwitch
  -----------------------------------------------
  OnBarSwitch = function(eventCode, isHotbarSwap)
    if isHotbarSwap then
      AIB.plugins.Poisons.UpdatePoisons()
    end
  end,

}


-------------------------------------------------
-- SETTINGS MENU
-------------------------------------------------
AIB.plugins.Poisons.Menu = {
  {
    type = "submenu",
    name = AIB.icons.Poisons..AIB.colors.blue.."Poisons|r",
    controls = {
      {
        type = "description",
        text = AIB.colors.orange.."Display the amount of poison on active weapons. These settings are per character.|r",
      },
      {
        type = "checkbox",
        name = "Enabled",
        tooltip = "Enables this plugin when checked",
        getFunc = function() return AIB.saved.character.Poisons.on end,
        setFunc = function(newValue) AIB.saved.character.Poisons.on = newValue; AIB.plugins.Poisons.RegisterEvents(); AIB.plugins.Poisons.UpdatePoisons() end,
        default = AIB.defaults.Poisons.on,
      },
      {
        type = "checkbox",
        name = "Only show when poison is low",
        tooltip = "If checked, Poisons will only display if the warning or critical threshold has been reached. If not checked, Poisons will always be displayed.",
        getFunc = function() return not AIB.saved.character.Poisons.alwaysOn end,
        setFunc = function(newValue) AIB.saved.character.Poisons.alwaysOn = not newValue; AIB.plugins.Poisons.UpdatePoisons() end,
        disabled = function() return not(AIB.saved.character.Poisons.on) end,
        default = not AIB.defaults.Poisons.alwaysOn,
      },
      {
        type = "slider",
        name = "Low Poisons "..AIB.colors.yellow.."warning|r",
        tooltip = "If remaining poison is this many or less, you will see a warning",
        min  = 1,
        max = 25,
        step = 1,
        getFunc = function() return AIB.saved.character.Poisons.warning end,
        setFunc = function(newValue) AIB.saved.character.Poisons.warning = newValue; AIB.plugins.Poisons.UpdatePoisons() end,
        disabled = function() return (not(AIB.saved.character.Poisons.on) or AIB.saved.character.Poisons.alwaysOn) end,
        default = AIB.defaults.Poisons.warning,
      },
      {
        type = "slider",
        name = "Low Poisons "..AIB.colors.red.."critical|r",
        tooltip = "If remaining poison is this many or less, you will see a critical warning",
        min  = 1,
        max = 25,
        step = 1,
        getFunc = function() return AIB.saved.character.Poisons.critical end,
        setFunc = function(newValue) AIB.saved.character.Poisons.critical = newValue; AIB.plugins.Poisons.UpdatePoisons() end,
        disabled = function() return (not(AIB.saved.character.Poisons.on) or AIB.saved.character.Poisons.alwaysOn) end,
        default = AIB.defaults.Poisons.critical,
      },
    }
  }
}
