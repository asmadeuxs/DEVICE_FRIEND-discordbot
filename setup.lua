local api = require("discordia")
local gi = api.enums.gatewayIntent
--[[local interactions = require("discordia-interactions")

function interactions.EventHandler.interaction_create_prelisteners.slashCommands(intr, client)
  if intr.type == api.enums.interactionType.applicationCommand and intr.data.type == 1 then
    client:emit('slashCommand', intr)
  end
end

function interactions.EventHandler.interaction_create_prelisteners.autocomplete(intr, client)
  if intr.type == api.enums.interactionType.applicationCommandAutocomplete and intr.data.type == 1 then
    client:emit('slashCommandAutocomplete', intr)
  end
end]]

local client = api.Client {
  maxRetries = 3,
  routeDelay = 3000,
  logFile = "logs/discordia.log"
}
client:enableIntents(gi.messageContent, gi.guildMembers)

client:on("ready", function()
  print("Bot is Ready", tostring(client.user.username))
end)

local messageHooks = require("hooks.message")
local memberHooks = require("hooks.members")

client:on("messageCreate", messageHooks.messageCreate)
client:on("memberUpdate", memberHooks.memberUpdate)

return function(token, settings)
  client:run("Bot " .. token, settings)
end
