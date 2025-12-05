local utf8 = require("utf8")
local SPACE_TRIM_MATCH = "^%s*(.-)%s*$"

--- Checks if a string starts with something.
--- @param x string
--- @param s string 		Starts with...
--- @return boolean
function string.startswith(x, s)
  return string.sub(x, 1, #s) == s
end

--- Checks if a string ends with something.
--- @param x string
--- @param e string What should it end with?
--- @return boolean
function string.endswith(x, e)
  return string.sub(x, - #e) == e
end

--- Trims a string using a pattern, trims spaces by default.
---
--- Sort of serves as a shortcut to string.gsub() with default patterns.
--- see [§6.4.1](https://www.lua.org/manual/5.4/manual.html#6.4.1)
--- @param x string
--- @param customPattern? string
--- @param replacement? string
--- @return string
--- @return integer count
function string.trim(x, customPattern, replacement)
  local p = type(customPattern) == "string" and customPattern or "%s+"
  local r = type(replacement) == "string" and replacement or ""
  return string.gsub(x, p, r)
end

--- Puts elements of a string in a table depending on the delimiter (UTF-8 unaware).
--- @see string.utf8split for an UTF-8 aware version of this same function.
--- @param x string
--- @param delimiter string
--- @param trimSpaces? boolean 		Trims spaces from the resulting table keys.
--- ```lua
--- local combo = string.split("500", "")
--- print(table.tostring(combo)) -- table 0x... {
---		[1] = "5",
---		[2] = "0",
---		[3] = "0"
---	}
--- local commaSeparated = ("apple,orange,banana"):split(",")
---	print(table.tostring(commaSeparated)) -- table 0x... {
---		[1] = "apple",
---		[2] = "orange",
---		[3] = "banana",
---	}
--- ```
--- @return table<string>
function string.split(x, delimiter, trimSpaces, seen)
  if #x == 0 then
    return {}
  end
  local out = {}
  if trimSpaces == nil then
    trimSpaces = false
  end
  local function gsplit(s)
    if trimSpaces then
      s = s:match("^%s*(.-)%s*$")
    end
    table.insert(out, s)
  end
  out = seen or {}
  x = string.gsub(x, (delimiter and delimiter ~= "") and "([^" .. delimiter .. "]+)" or ".", gsplit)
  return out
end

--- Similar to string.split, but splits the entire string for only words.
--- @param x string
--- @return table<string> with only words.
function string.splitwords(x)
  local words = {}
  for word in x:gmatch("%S+%s*") do
    table.insert(words, word)
  end
  return words
end

-- utf8 functions

--- Puts elements of a string in a table depending on the delimiter (UTF-8 aware).
--- @see string.split
--- @return table
function string.utf8split(x, delimiter, trimSpaces)
  if not x or x == "" then return {} end
  local result = {}
  if delimiter == nil or delimiter == "" then
    for _, code in utf8.codes(x) do
      table.insert(result, utf8.char(code))
    end
    return result
  end
  local start = 1
  --local length = #delimiter
  while true do
    local foundStart, foundEnd = x:find(delimiter, start, true)
    if not foundStart then
      break
    end
    local substring = string.sub(x, start, foundStart - 1)
    if trimSpaces then
      substring = string.match(substring, SPACE_TRIM_MATCH)
    end
    table.insert(result, substring)
    start = foundEnd + 1
  end
  local lastPart = string.sub(x, start)
  if trimSpaces then
    lastPart = string.match(lastPart, SPACE_TRIM_MATCH)
  end
  table.insert(result, lastPart)
  return result
end

--- Inverses an utf8 string.
--- @param str string
--- @return string
function string.utf8reverse(str)
  local chars = {}
  for _, code in utf8.codes(str) do
    table.insert(chars, 1, utf8.char(code))
  end
  return table.concat(chars)
end

--- string.sub but for utf8 strings.
--- @param str string
--- @param start number
--- @param finish number
--- @return string
function string.utf8sub(str, start, finish)
  if not str then return "" end
  if str == "" then return "" end

  if start == 0 then start = 1 end
  if finish == 0 then finish = 1 end

  local index = 1
  local positions = {}
  local chars = {}
  for pos, code in utf8.codes(str) do
    local uchar = utf8.char(code)
    if uchar then
      chars[index]= uchar
      positions[index] = pos
      index = index + 1
    end
  end
  local len = #chars
  -- handle negatives (like string.sub)
  if start < 0 then start = len + start + 1 end
  if finish and finish < 0 then finish = len + finish + 1 end
  finish = finish or len

  start = math.max(1, math.min(start, len))
  finish = math.max(1, math.min(finish, len))
  start, finish = math.floor(start), math.floor(finish)

  if start > finish then
    print(string.format("[string.utf8sub, WARNING] start is greater than end (start: %i, finish: %i)", start, finish))
    return ""
  end
  -- now extract
  local startByte = positions[start]
  local endByte
  if finish < len then
    endByte = positions[finish + 1] - 1
  else
    endByte = #str
  end
  return string.sub(str, startByte, endByte)
end

--- Gets the length of an utf8 string.
--- @param str string
--- @return number
function string.utf8len(str)
  if not str or type(str) ~= "string" then return 0 end
  if str == "" then return 0 end
  local count = 0
  local success, result = pcall(function()
    for _ in utf8.codes(str) do
      count = count + 1
    end
    return count
  end)
  if not success then
    print("[string.utf8len, WARNING]: Error in utf8len for string: " .. tostring(str))
    return #str
  end
  return result
end

--- @return number|nil
function string.utf8charat(str, position)
  if not str or type(str) ~= "string" then return nil end
  if position < 1 then return nil end
  local index = 1
  for _, code in utf8.codes(str) do
    if index == position then
      return utf8.char(code)
    end
    index = index + 1
  end
  return nil
end

--- string.find but for utf8 strings
--- @param str string
--- @param pattern string What to find
--- @param init number Where to start
--- @param plain? boolean Turns off pattern matching
function string.utf8find(str, pattern, init, plain)
  local byteStart, byteEnd = str:find(pattern, init, plain)
  if not byteStart then return nil end
  -- converting byte positions to utf8 positions (yes those are different.)
  local charStart, charEnd = 0, 0
  local charCount = 0
  for i, _ in utf8.codes(str) do
    charCount = charCount + 1
    if i == byteStart then charStart = charCount end
    if i == byteEnd then
      charEnd = charCount
      break
    end
  end
  if charEnd == 0 then charEnd = charStart end
  return charStart, charEnd
end

local UTF8_TRIM_PATTERN = "^[%s]*(.-)[%s]*$"

--- Trims a utf8 string.
--- @param str string
--- @param customPattern? string Custom pattern for trimming (default: "^[%s]*(.-)[%s]*$)
function string.utf8trim(str, customPattern)
  return string.match(str, customPattern or UTF8_TRIM_PATTERN)
end
