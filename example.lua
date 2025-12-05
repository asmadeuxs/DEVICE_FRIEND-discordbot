-- example for setting up the bot.
-- you WILL need discordia to run this bot
-- @see https://github.com/SinisterRectus/Discordia

local BOT_TOKEN = "YOUR-DISCORD-BOT-TOKEN-HERE"

local api = require("discordia")
local client = api.Client {
  maxRetries = 3,
  routeDelay = 3000,
  logFile = "logs/discordia.log"
}
local gi = api.enums.gatewayIntent
client:enableIntents(gi.messageContent, gi.guildMembers)
require("hooks.setup")(client)

client:run("Bot " .. BOT_TOKEN, {
  activity = "WORK IN PROGRESS",
  status = "idle"
})
