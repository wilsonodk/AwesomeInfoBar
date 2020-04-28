
----------------------------------------------------
-- ICONS
----------------------------------------------------
AIB.icons["Experience"]         =  "|t38:38:esoui/art/treeicons/achievements_indexicon_summary_up.dds|t"
AIB.icons["ExperienceCritical"] =  "|t38:38:esoui/art/treeicons/achievements_indexicon_summary_up.dds|t"
AIB.icons["ExperienceWarning"]  =  "|t38:38:esoui/art/treeicons/achievements_indexicon_summary_up.dds|t"

----------------------------------------------------
-- SAVED VARS
----------------------------------------------------
AIB.defaults["Experience"] = {
  on              = true,
  alwaysOn        = true,
  warning         = 5,       -- minutes
  critical        = 2,       -- minutes
}

----------------------------------------------------
-- LOCAL VARS
----------------------------------------------------
AIB.vars["Experience"] = {
  lastUpdate = 0,
  frequency = 10,
  buffs = {
    [63570]   = true,   -- "Increased Experience"
    [66776]   = true,   -- "Increased Experience"
    [77123]   = true,   -- "Anniversary experience bonus"
    [85501]   = true,   -- "Increased Experience"
    [85502]   = true,   -- "Increased Experience"
    [85503]   = true,   -- "Increased Experience"
    [86755]   = true,   -- "Holiday experience bonus"
    [91369]   = true,   -- "increased experience of the fool's pie"
    [92232]   = true,   -- "Pelinals savagery"
    [99462]   = true,   -- "Increased Experience"
    [99463]   = true,   -- "Increased Experience"
    [118985]  = true,   -- "Anniversary experience bonus"
  },
  scrolls = {
    [64537]   = true,     -- Crown Experience Scroll
    [94439]   = true,     -- Gold Coast Experience Scroll
    [94440]   = true,     -- Major Gold Coast Experience Scroll
    [94441]   = true,     -- Grand Gold Coast Experience Scroll
    [135110]  = true,     -- Crown Experience Scroll
    [138811]  = true,     -- Crown Experience Scroll (2)
  }
}

----------------------------------------------------
-- METHODS CALLED FROM PARENT
----------------------------------------------------
AIB.plugins["Experience"] = {

  ------------------------------------------------
  -- PARENT METHOD: Initialize
  ------------------------------------------------
  Initialize = function()
    AIB.plugins.Experience.UpdateExperience()
  end,

  ------------------------------------------------
  -- PARENT METHOD: Update (every 1 sec)
  ------------------------------------------------
  Update = function()
    if (AIB.saved.account.Experience.on) then
      -- less frequent update (10 sec default)
      AIB.vars.Experience.lastUpdate = AIB.vars.Experience.lastUpdate + 1
      if (AIB.vars.Experience.lastUpdate > AIB.vars.Experience.frequency) then
        AIB.vars.Experience.lastUpdate = 0
        AIB.plugins.Experience.UpdateExperience()
      end
    end
  end,

  -----------------------------------------------
  -- METHOD: GetActiveXPBuff()
  -- Returns
  --  boolean             Is a XP buff active?
  --  number    Nilable   Raw time left in seconds
  --  string    Nilable   Formatted time left, as `[xh ]ym` where `x` is hours and `y` is minutes
  -----------------------------------------------
  GetActiveXPBuff = function()
    local unitTag = "player"
    local numOfBuffs = GetNumBuffs(unitTag)
    local timeLeft, timeLeftFormatted
    local showBuff = false

    for i = 1, numOfBuffs do
      local buffName, timeStarted, timeEnding, buffSlot, stackCount, iconFilename, buffType, effectType, abilityType, statusEffectType, abilityId, canClickOff, castByPlayer = GetUnitBuffInfo(unitTag, i)

      if abilityId ~= nil then
        if AIB.vars.Experience.buffs[abilityId] == true then
          timeLeft = AIB.GetTimeLeft(timeEnding)
          timeLeftFormatted = AIB.GetTimerDisplay(timeLeft)
          showBuff = true
          break
        end
      end
    end

    return showBuff, timeLeft, timeLeftFormatted
  end,

  ------------------------------------------------
  -- METHOD: HaveExperienceScroll
  -- Returns
  --  boolean     Have an experience scroll on person or in the bank
  --  boolean     Have an experience scroll on person
  --  boolean     Have an experience scroll in bank
  ------------------------------------------------
  HaveExperienceScroll = function()
    local packSize = GetBagSize(BAG_BACKPACK)
    local haveScroll = false
    local inPack = false
    local inBank = false

    -- Actually check to see if we have a scroll
    for index = 1, packSize do
      local itemLink = GetItemLink(BAG_BACKPACK, index)

      if itemLink ~= "" then
        local itemId = GetItemLinkItemId(itemLink)

        if itemId ~= "" then
          itemId = tonumber(itemId)

          if AIB.vars.Experience.scrolls[itemId] == true then
            haveScroll = true
            inPack = true
            break
          end
        end
      end
    end

    if not haveScroll then
      packSize = GetBagSize(BAG_BANK)

      for index = 1, packSize do
        local itemLink = GetItemLink(BAG_BANK, index)

        if itemLink ~= "" then
          local itemId = GetItemLinkItemId(itemLink)

          if itemId ~= "" then
            itemId = tonumber(itemId)

            if AIB.vars.Experience.scrolls[itemId] == true then
              haveScroll = true
              inBank = true
              break
            end
          end
        end
      end
    end

    if not haveScroll and IsESOPlusSubscriber() then
      packSize = GetBagSize(BAG_SUBSCRIBER_BANK)

      for index = 1, packSize do
        local itemLink = GetItemLink(BAG_SUBSCRIBER_BANK, index)

        if itemLink ~= "" then
          local itemId = GetItemLinkItemId(itemLink)

          if itemId ~= "" then
            itemId = tonumber(itemId)

            if AIB.vars.Experience.scrolls[itemId] == true then
              haveScroll = true
              inBank = true
              break
            end
          end
        end
      end
    end

    return haveScroll, inPack, inBank
  end,

  ------------------------------------------------
  -- METHOD: UpdateExperience
  ------------------------------------------------
  UpdateExperience = function()
    local snoozing = AIB.isSnoozing("Experience")
    AIB.setLabel("Experience","")

    -- if show experience
    if (AIB.saved.account.Experience.on and not snoozing) then
      local header, value = "",""
      local isWarning, isCritical = false, false

      -- get data
      local isBuffActive, xpTime, xpTimeFormatted = AIB.plugins.Experience.GetActiveXPBuff()

      -- set warnings
      if isBuffActive then
        if (xpTime <= AIB.saved.account.Experience.warning) then
          if (xpTime <= AIB.saved.account.Experience.critical) then
            isCritical = true
          else
            isWarning = true
          end
        end
      else
        isCritical = true
      end

      -- set header
      header = AIB.setHeader("Experience", isWarning, isCritical)

      -- set value
      if isBuffActive then
        value = AIB.setValue(xpTimeFormatted, isWarning, isCritical)
      else
        local haveScroll, scrollInPack, scrollInBank = AIB.plugins.Experience.HaveExperienceScroll()

        if haveScroll then
          if scrollInPack then
            value = AIB.setValue("Use Scroll!", isWarning, isCritical)
          else
            value = AIB.setValue("In Bank!", isWarning, isCritical)
          end
        else
          value = AIB.setValue("Need Scroll", false, false)
        end
      end

      -- set label
      if ((not AIB.saved.account.Experience.alwaysOn and (isWarning or isCritical))
        or (AIB.saved.account.Experience.alwaysOn)) then
        AIB.setLabel("Experience", header..value)
      end
    end
  end,
}

----------------------------------------------------
-- SETTINGS MENU
----------------------------------------------------
AIB.plugins.Experience.Menu = {
  {
    type = "submenu",
    name = AIB.icons.Experience..AIB.colors.blue.."Experience Buff Timer|r",
    controls = {
      {
        type = "description",
        text = AIB.colors.orange.."Display a countdown timer for experience buff duration.|r",
      },
      {
        type = "checkbox",
        name = "Enabled",
        tooltip = "Enables this plugin when checked",
        getFunc = function() return AIB.saved.account.Experience.on end,
        setFunc = function(newValue) AIB.saved.account.Experience.on = newValue; AIB.plugins.Experience.UpdateExperience() end,
        default = AIB.defaults.Experience.on,
      },
      {
        type = "checkbox",
        name = "Only show when timer is low",
        tooltip = "If checked, experience buff will only display if the warning or critical threshold has been reached. If not checked, experience buffs will always be displayed.",
        getFunc = function() return not AIB.saved.account.Experience.alwaysOn end,
        setFunc = function(newValue) AIB.saved.account.Experience.alwaysOn = not newValue; AIB.plugins.Experience.UpdateExperience(); end,
        disabled = function() return not(AIB.saved.account.Experience.on) end,
        default = not AIB.defaults.Experience.alwaysOn,
      },
      {
        type = "slider",
        name = "Low Experience Buff "..AIB.colors.yellow.."warning|r (minutes)",
        tooltip = "If number of minutes remaining is this many or less, you will see a warning.",
        min  = 1,
        max = 30,
        getFunc = function() return AIB.saved.account.Experience.warning end,
        setFunc = function(newValue) AIB.saved.account.Experience.warning = newValue; AIB.plugins.Experience.UpdateExperience() end,
        disabled = function() return not(AIB.saved.account.Experience.on) end,
        default = AIB.defaults.Experience.warning,
      },
      {
        type = "slider",
        name = "Low Experience Buff "..AIB.colors.red.."critical warning|r (minutes)",
        tooltip = "If number of minutes remaining is this many or less, you will see a critical warning.",
        min  = 1,
        max = 15,
        getFunc = function() return AIB.saved.account.Experience.critical end,
        setFunc = function(newValue) AIB.saved.account.Experience.critical = newValue; AIB.plugins.Experience.UpdateExperience() end,
        disabled = function() return not(AIB.saved.account.Experience.on) end,
        default = AIB.defaults.Experience.critical,
      }
    }
  }
}
