local commands = require("hooks.commands")
local REPLACE_NICKNAMES = require("data.randomNames")

return {
  memberUpdate = function(member)
    if not member.bot then
      for _, prohibited in ipairs(commands._getUserBlacklist(member.guild.id) or {}) do
        local pattern = string.format("(%s)", prohibited:lower())
        if member.name:lower():match(pattern) then
          local random = table.pickrandom(REPLACE_NICKNAMES)
          local ok = member:setNickname(tostring(random))
          if ok then
            print("Forbidden nickname detected for user " .. member.name .. ", the nickname will be set to " .. tostring(random) .. ".")
            member.user:send(
              "HEY, YOUR NICKNAME CONTAINS THE PROHIBITED TERM \"" .. prohibited ..
              "\" WHICH ISN'T ALLOWED IN \"" .. member.guild.name ..
              "\"! I'M CHANGING IT TO " .. tostring(random) .. " JUST TO MAKE FUN OF YOU." ..
              "\n\n`THIS IS AN AUTOMATED MESSAGE, I'M NOT REAL!`")
          end
        end
      end
    end
  end
}
