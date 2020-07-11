
----------------------------------------------------
-- ICONS
----------------------------------------------------
AIB.icons["Mail"]          =  "|t24:24:esoui/art/mail/mail_inbox_unreadmessage.dds|t "
AIB.icons["MailCritical"]  =  "|t24:24:esoui/art/mail/mail_inbox_unreadmessage.dds|t "
AIB.icons["MailWarning"]   =  "|t24:24:esoui/art/mail/mail_inbox_unreadmessage.dds|t "

----------------------------------------------------
-- SAVED VARS
----------------------------------------------------
AIB.defaults["Mail"] = {
  on       = true,
  alwaysOn = false,
  warning  = 1,
  critical = 5
}

----------------------------------------------------
-- LOCAL VARS
----------------------------------------------------
AIB.vars["Mail"] = {
  lastUpdate  = 0,
  frequency   = 10
}

----------------------------------------------------
-- METHODS CALLED FROM PARENT
----------------------------------------------------
AIB.plugins["Mail"] = {

  ------------------------------------------------
  -- PARENT METHOD: Initialize
  ------------------------------------------------
  Initialize = function()
    AIB.plugins.Mail.UpdateMail()
  end,


  ------------------------------------------------
  -- PARENT METHOD: Update (every 1 sec)
  ------------------------------------------------
  Update = function()
    if (AIB.saved.account.Mail.on) then
      -- less frequent update (10 sec default)
      AIB.vars.Mail.lastUpdate = AIB.vars.Mail.lastUpdate + 1
      if (AIB.vars.Mail.lastUpdate > AIB.vars.Mail.frequency) then
        AIB.vars.Mail.lastUpdate = 0
        AIB.plugins.Mail.UpdateMail()
      end
    end
  end,


  ------------------------------------------------
  -- PARENT METHOD: RegisterEvents
  ------------------------------------------------
  RegisterEvents = function()
    if (AIB.saved.account.BankSpace.on) then
      EVENT_MANAGER:RegisterForEvent("AIB_Mail", EVENT_MAIL_CLOSE_MAILBOX, AIB.plugins.Mail.OnMailboxClose)
    else
      EVENT_MANAGER:UnregisterForEvent("AIB_Mail", EVENT_MAIL_CLOSE_MAILBOX)
    end
  end,


  ------------------------------------------------
  -- EVENT: OnMailboxClose (number eventCode)
  ------------------------------------------------
  OnMailboxClose = function(eventCode)
    AIB.plugins.Mail.UpdateMail()
  end,


  ------------------------------------------------
  -- METHOD: UpdateMail
  ------------------------------------------------
  UpdateMail = function()
    local snoozing = AIB.isSnoozing("Mail")
    AIB.setLabel("Mail", "")

    -- if show mail
    if (AIB.saved.account.Mail.on and not snoozing) then
      local header, value = "", ""
      local isWarning, isCritical = false, false

      -- get data
      local mailCount = GetNumUnreadMail()

      -- set warnings
      if (mailCount >= AIB.saved.account.Mail.warning) then
        if (mailCount >= AIB.saved.account.Mail.critical) then
          isCritical = true
        else
          isWarning = true
        end
      end

      -- set header
      header = AIB.setHeader("Mail", isWarning, isCritical)

      -- set value
      value = AIB.setValue("Unread: "..mailCount, isWarning, isCritical)

      -- set label
      if ((not AIB.saved.account.Mail.alwaysOn and (isWarning or isCritical))
        or (AIB.saved.account.Mail.alwaysOn)) then
        AIB.setLabel("Mail", header..value)
      end
    end
  end,
}


----------------------------------------------------
-- SETTINGS MENU
----------------------------------------------------
AIB.plugins.Mail.Menu = {
  {
    type = "submenu",
    name = AIB.icons.Mail..AIB.colors.blue.."Mailbox|r",
    controls = {
      {
        type = "description",
        text = AIB.colors.orange.."Displays a count of unread mail.|r",
      },
      {
        type = "checkbox",
        name = "Enabled",
        tooltip = "Enables this plugin when checked",
        getFunc = function() return AIB.saved.account.Mail.on end,
        setFunc = function(newValue) AIB.saved.account.Mail.on = newValue; AIB.plugins.Mail.RegisterEvents(); AIB.plugins.Mail.UpdateMail() end,
        default = AIB.defaults.Mail.on,
      },
      {
        type = "checkbox",
        name = "Only show when there is unread mail",
        tooltip = "If checked, will only display when there is unread mail.",
        getFunc = function() return not AIB.saved.account.Mail.alwaysOn end,
        setFunc = function(newValue) AIB.saved.account.Mail.alwaysOn = not newValue; AIB.plugins.Mail.UpdateMail(); end,
        disabled = function() return not(AIB.saved.account.Mail.on) end,
        default = not AIB.defaults.Mail.alwaysOn,
      },
      {
        type = "slider",
        name = "Unread mail "..AIB.colors.yellow.."warning|r (count)",
        tooltip = "If you have this many unread messages, you will see a warning. Default 1.",
        min  = 1,
        max = 20,
        getFunc = function() return AIB.saved.account.Mail.warning end,
        setFunc = function(newValue) AIB.saved.account.Mail.warning = newValue; AIB.plugins.Mail.UpdateMail() end,
        disabled = function() return not(AIB.saved.account.Mail.on) end,
        default = AIB.defaults.Mail.warning,
      },
      {
        type = "slider",
        name = "Unread mail "..AIB.colors.red.."critical warning|r (count)",
        tooltip = "If you have this many unread messages or more, you will see a critical warning. Default 5.",
        min  = 1,
        max = 30,
        getFunc = function() return AIB.saved.account.Mail.critical end,
        setFunc = function(newValue) AIB.saved.account.Mail.critical = newValue; AIB.plugins.Mail.UpdateMail() end,
        disabled = function() return not(AIB.saved.account.Mail.on) end,
        default = AIB.defaults.Mail.critical,
      }
    }
  }
}
