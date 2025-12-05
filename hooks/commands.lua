require("util.table") -- additional table overrides

local DEFAULT_NICKNAME_BLACKLIST = {}
local DEFAULT_WORD_BLACKLIST = {} -- if I ever re-add print, I should add this
local DEFAULT_COOLDOWN_AMOUNT = 3000.0 -- 300ms (3 seconds)
local DEFAULT_PREFIX = ">>"

local function initGuild(blacklistedNicknames)
	return {
	  botPrefix = DEFAULT_PREFIX,
		commandCooldown = DEFAULT_COOLDOWN_AMOUNT,
		blacklistedNicknames = blacklistedNicknames or DEFAULT_NICKNAME_BLACKLIST,
	}
end

local curVer = require("util.buildNumber")

local commands = {
  version = curVer,
  guilds = {},
}

local function botPrint(msg, args, preventAutoDelete)
  if type(preventAutoDelete) ~= "boolean" then
    preventAutoDelete = false
  end
  if #args > 1 then
    local message = table.concat(args, " ", 2)
    local msgAuthor = msg.author.tag
    local isDM = msg.channel.name == msgAuthor
    if isDM then
      print(("%s called print in their DMs, Message: %s"):format(msgAuthor, message))
    else
      local guildName = (msg.guild and msg.guild.name or "NO GUILD/DIRECT MESSAGES") .. ":#" .. msg.channel.name
      if msg.author.tag ~= msg.author.globalName then
        msgAuthor = ("%s (globally: %s)"):format(msgAuthor, msg.author.globalName)
        print(("%s called print in %s, Message: %s"):format(msgAuthor, guildName, message))
      end
    end
    msg.channel:send(tostring(message):upper())
    if not isDM and not preventAutoDelete then
      msg:delete()
    end
  else
    msg.channel:send("I CAN'T JUST SAY NOTHING!")
  end
end

local json = require("util.json")

local function saveGuilds()
  local encoded = json.encode(commands.guilds, true)
  local file = io.open("data/guildsettings.json", "w")
  file:write(encoded)
  file:close()
end

local function loadGuilds()
  local jsonfile = ""
  for i, _ in io.open("data/guildsettings.json", "r"):lines() do
    jsonfile = jsonfile .. i .. "\n"
  end
  if #jsonfile == 0 then
    jsonfile = "{}"
  end
  local guilds = json.decode(jsonfile) or {}
  return guilds
end

function commands.prohibitNicknames(msg, args)
  local isDM = msg.channel.name == msg.author.tag
  if not msg.guild and isDM then
    msg:reply("THIS COMMAND WILL NOT WORK IN DMS!")
    return
  end
  local author = msg.guild:getMember(msg.author.id)
  if not author:hasPermission("manageNicknames") then
    local reply = msg:reply("YOU CANNOT EXECUTE THIS COMMAND BECAUSE YOU NEED TO HAVE THE `manageNicknames` PERMISSION!")
    os.execute("sleep 5")
    reply:delete()
    msg:delete()
    return
  end
  local guildID = tostring(msg.guild.id)
  if #args > 1 then
    local blacklist = table.concat(args, ", ", 2)
    if guildID then
      if not commands.guilds[guildID] then
        commands.guilds[guildID] = initGuild()
      end
      local namesAdded = {}
      local namesChecked = {}
      for i = 2, #args do
        local _nnblacklist = commands.guilds[guildID].blacklistedNicknames
        local index = table.find(_nnblacklist, args[i])
        if index == nil then
          table.insert(_nnblacklist, args[i])
          table.insert(namesAdded, args[i])
        end
        table.insert(namesChecked, args[i])
      end
      if #namesAdded > 0 then
        print("Guild " .. tostring(msg.guild.name) .. " just blacklisted these nicknames: " .. blacklist)
        msg.channel:send(
          ("THE NICKNAME(S) **\"%s\"** HAVE BEEN BLACKLISTED! USERS WILL NOT BE ABLE TO USE THEM"):format(blacklist)
        )
        saveGuilds()
      else
        msg.channel:send(
          ("THE NICKNAMES(S) **\"%s\"** " .. (#namesChecked == 1 and "IS" or "ARE") .. " ALREADY PART OF THE BLACKLIST!"):format(blacklist)
        )
      end
    end
  else
    msg.channel:send(
      "YOU DIDN'T GIVE ME ANY NICKNAMES TO BLACKLIST!\nGIVE ME AT LEAST ONE NICKNAME AFTER TYPING THE COMMAND..." ..
      "\nYOU CAN ALSO GIVE ME MULTIPLE NICKNAMES TO BLACKLIST, BUT YOU MUST SEPARATE THEM WITH SPACES!" ..
      "\nEXAMPLE: `" .. commands._getGuildPrefix(guildID) .. "prohibitNicknames everyone here`"
    )
  end
end

function commands.allowNicknames(msg, args)
  local isDM = msg.channel.name == msg.author.tag
  if not msg.guild and isDM then
    msg:reply("THIS COMMAND WILL NOT WORK IN DMS!")
    return
  end
  local author = msg.guild:getMember(msg.author.id)
  if not author:hasPermission("manageNicknames") then
    local reply = msg:reply("YOU CANNOT EXECUTE THIS COMMAND BECAUSE YOU NEED TO HAVE THE `manageNicknames` PERMISSION!")
    os.execute("sleep 5")
    reply:delete()
    msg:delete()
    return
  end
  local guildID = tostring(msg.guild.id)
  if #args > 1 then
    local justAllowed = {}
    local alreadyAllowed = {}
    if guildID then
      if not commands.guilds[guildID] then
        commands.guilds[guildID] = initGuild()
      end
      local blacklist = commands.guilds[guildID].blacklistedNicknames
      for i = 2, #args do
        local name = args[i]
        local index = table.find(blacklist, name)
        if index ~= nil then
          table.remove(commands.guilds[guildID].blacklistedNicknames, index)
          print("Allowing name \"" .. name .. "\"")
          table.insert(justAllowed, name)
        else
          table.insert(alreadyAllowed, name)
        end
      end
      if #justAllowed > 0 then
        msg.channel:send(("THE NICKNAME(S) **\"%s\"** ARE NOW ALLOWED TO BE USED AGAIN"):format(table.concat(justAllowed, ", ")))
        if #alreadyAllowed > 0 then
          local note = msg.channel:send(
            ("NOTE THAT *\"%s\"* " .. (#alreadyAllowed == 1 and "WAS" or "WERE") .." ALREADY OUTSIDE OF THE NICKNAME BLACKLIST, " ..
              "SO I DIDN'T DO ANYTHING WITH " .. (#alreadyAllowed == 1 and "IT" or "THOSE.")):format(table.concat(alreadyAllowed, ", ")))
          os.execute("sleep 3")
          note:delete()
        end
        saveGuilds()
      else
        if #alreadyAllowed > 0 then
          msg.channel:send(("USERS CAN ALREADY NAME THEMSELVES *\"%s\"*, SO I DIDN'T DO ANYTHING."):format(table.concat(alreadyAllowed, ", ")))
        end
      end
    end
  else
    msg.channel:send(
      "YOU DIDN'T GIVE ME ANY NICKNAMES TO ALLOW!\nGIVE ME AT LEAST ONE NICKNAME AFTER TYPING THE COMMAND..." ..
      "\nYOU CAN ALSO GIVE ME MULTIPLE NICKNAMES TO ALLOW, BUT YOU MUST SEPARATE THEM WITH SPACES!" ..
      "\nEXAMPLE: `" .. commands._getGuildPrefix(guildID) .. "allowNicknames everyone here`"
    )
  end
end

function commands.changePrefix(msg, args)
  local isDM = msg.channel.name == msg.author.tag
  if not msg.guild and isDM then
    msg:reply("THIS COMMAND WILL NOT WORK IN DMS!")
    return
  end
  local author = msg.guild:getMember(msg.author.id)
  if not author:hasPermission("manageGuild") then
    local reply = msg:reply("YOU CANNOT EXECUTE THIS COMMAND BECAUSE YOU NEED TO HAVE THE `manageGuild (Manage Server)` PERMISSION!")
    os.execute("sleep 5")
    reply:delete()
    msg:delete()
    return
  end
  local newPrefix = args[2]
  if not newPrefix or #newPrefix == 0 then
    msg:reply("GIVE ME AN ACTUAL PREFIX! YOU GAVE ME NOTHING!")
    return
  end
  local guildID = tostring(msg.guild.id)
  if guildID ~= nil and not commands.guilds[guildID] then
    commands.guilds[guildID] = initGuild()
  end
  if newPrefix == nil or newPrefix == "nil" or newPrefix == "null" or newPrefix == "default" then
    local ok, err = pcall(function()
      commands.guilds[guildID].prefix = DEFAULT_PREFIX
      msg:reply("MY PREFIX HAS CHANGED TO MY DEFAULT ONE. `" .. tostring(DEFAULT_PREFIX) .. "`")
    end)
    if not ok then
      msg:reply("I CAUGHT AN ERROR PROCESSING `changePrefix` THE LAST TIME IT GOT CALLED, PLEASE REPORT TO MY DEVELOPER (ERR: `" .. tostring(err) .. "`")
      print("Guild " .. msg.guild.name .. " tried to reset the bot prefix, but got an error: " .. err)
    else
      saveGuilds()
    end
  else
    local ok, err = pcall(function()
      commands.guilds[guildID].botPrefix = tostring(newPrefix)
      msg:reply("MY PREFIX HAS CHANGED TO `" .. tostring(newPrefix) .. "`.")
    end)
    if not ok then
      msg:reply("I CAUGHT AN ERROR PROCESSING `changePrefix` THE LAST TIME IT GOT CALLED, PLEASE REPORT TO MY DEVELOPER (ERR: `" .. tostring(err) .. "`")
      print("Guild " .. msg.guild.name .. " tried to change the bot prefix, but got an error: " .. err)
    else
      saveGuilds()
    end
  end
end

--[[function commands.print(msg, args)
  botPrint(msg, args, false)
end]]

--[[function commands.printd(msg, args)
  botPrint(msg, args, true)
end]]

--[[function commands.thegif(msg, _)
  --local isDM = msg.channel.name == msg.author.tag
  --if not isDM then msg:delete() end
  msg.channel:send("https://tenor.com/view/deltarune-friend-cat-image-friend-gif-16014775164715111297")
end]]

local REPLACE_NICKNAMES = require("data.randomNames")

function commands.nicknameMe(msg, _)
  local isDM = not msg.guild and msg.channel.name == msg.author.tag
  local randomName = table.pickrandom(REPLACE_NICKNAMES)
  if not isDM then
    local author = msg.guild:getMember(msg.author.id)
    if not author:hasPermission("changeNickname") then
      local reply = msg:reply("YOU CANNOT EXECUTE THIS COMMAND BECAUSE YOU NEED TO HAVE THE `changeNickname` PERMISSION!")
      os.execute("sleep 5")
      reply:delete()
    end

    if author:hasPermission("administrator") then
      msg:reply("I CAN'T DO THAT TO YOU, BOSS, BUT HERE'S A RANDOM NAME I ROLLED! \"" .. tostring(randomName) .."\"!")
      return
    end
    local ok = author:setNickname(tostring(randomName))
    if ok then
      msg:reply("I CHANGED YOUR NAME TO \"" .. randomName .. "\" SINCE YOU ASKED SO NICELY!")
    else
      print("Failed to change " .. author.name .. "'s nickname")
    end
  else
    msg:reply("MAYBE TRY CALLING YOURSELF \"" .. randomName .. "\"!")
  end
end

function commands.help(msg, _)
  local currentPrefix = commands._getGuildPrefix(msg.guild and msg.guild.id or nil)
  local isDM = not msg.guild and msg.channel.name == msg.author.tag
  msg.channel:send {
    embed = {
      title = "YOU CALLED?",
      description = "THESE ARE ALL MY COMMANDS",
      --"\n`" .. currentPrefix .. "print ANY TEXT` - I WILL REPEAT WHAT YOU TELL ME TO. YOUR MESSAGE ALSO GETS DELETED IN FAVOUR OF MINE\n" ..
      --"\n`" .. currentPrefix .. "printd ANY TEXT` - VARIANT OF `print` BUT I WON'T DELETE YOUR MESSAGE\n" ..
      fields = {
        {
          name = "nicknameMe",
          value = "(SERVER-MAINLY, SUGGESTS FOR ADMINS/IN DMS) I'LL ROLL A DICE AND DECIDE WHAT YOUR NICKNAME WILL BE!",
          inline = false
        },
        {
          name = "changePrefix",
          value = "(SERVER-ONLY) CHANGES MY PREFIX TO SOMETHING ELSE, YOU CAN PASS `null`, `nil`, OR `default` TO RESET IT TO `" .. DEFAULT_PREFIX .. "`\n",
          inline = false
        },
        {
          name = "prohibitNicknames",
          value = "(SERVER-ONLY) I WILL REMEMBER THE NICKNAMES YOU GIVE ME AND RENAME MEMBERS THAT TRY TO USE THEM FOR YOU (YOU WILL NEED THE `manageNicknames` PERMISSION)",
          inline = false
        },
        {
          name = "allowNicknames",
          value = "(SERVER-ONLY) THE OPPOSITE OF `prohibitNicknames`!",
          inline = false
        },
        {
          name = "getInfo",
          value = "YOU SEE THE FOOTER DOWN THERE? THIS COMMAND MAKES ME SEND IT IN PLAIN TEXT",
          inline = false
        }
      },
      footer = {
        text = "" .. (not isDM and string.format("\n\nMY CURRENT PREFIX IS `%s` - ", currentPrefix) or "") .. "I'M CURRENTLY IN VERSION " .. tostring(curVer)
      },
    }
  }
end

function commands.getInfo(msg, _)
  if msg.guild then
    local currentPrefix = commands._getGuildPrefix(msg.guild and msg.guild.id or nil)
    msg.channel:send("MY CURRENT PREFIX IS `" .. currentPrefix .. "` - I'M CURRENTLY IN VERSION " .. tostring(curVer))
  else
    msg.channel:send("I'M CURRENTLY IN VERSION " .. tostring(curVer))
  end
end

function commands._getUserBlacklist(guildID)
  if guildID == nil or not commands.guilds[guildID] then
    return DEFAULT_NICKNAME_BLACKLIST
  end
  local blacklist = commands.guilds[guildID].blacklistedNicknames
  if type(blacklist) ~= "table" then blacklist = DEFAULT_NICKNAME_BLACKLIST end
  return blacklist
end

function commands._getGuildPrefix(guildID)
  if guildID == nil or not commands.guilds[guildID] then
    return DEFAULT_PREFIX
  end
  local prefix = commands.guilds[guildID].botPrefix
  if type(prefix) ~= "string" then prefix = DEFAULT_PREFIX end
  return prefix
end

commands.guilds = loadGuilds()

return commands
