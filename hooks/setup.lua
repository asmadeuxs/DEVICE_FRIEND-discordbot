require("util.string") -- additional string overrides
local messageHooks = require("hooks.message")
local memberHooks = require("hooks.members")

--- Master function to setup all hooks
return function(client)
  local ok, err = pcall(function()
    client:on("ready", function()
      print("Bot is Ready", tostring(client.user.username))
    end)
    client:on("messageCreate", messageHooks.messageCreate)
    client:on("memberUpdate", memberHooks.memberUpdate)
  end)
  if not ok then
    error("Error setting up hooks: " .. tostring(err), 1)
  end
end
