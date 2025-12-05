local commands = require("hooks.commands")

return {
  messageCreate = function(msg)
    if not msg or msg.author.bot then return end
    local currentPrefix = commands._getGuildPrefix(msg.guild and msg.guild.id or nil)
    if string.startswith(msg.content, "^") then
      -- dev commands
    elseif string.startswith(msg.content, currentPrefix) then
      local args = string.split(msg.content, " ")
      local exec = args[1]:sub(#currentPrefix + 1)
      if not string.startswith(exec, "_") then
        local cmd = commands[exec]
        if cmd then cmd(msg, args) end
      end
    end
  end,
}
