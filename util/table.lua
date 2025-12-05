-- Backwards compatibility --
table.pack = table.pack or function(...)
  return { n = select("#", ...), ... }
end
table.unpack = table.unpack or unpack

function table.pickrandom(tbl)
  if not tbl or #tbl < 2 then return #tbl == 0 and nil or 1 end
  return tbl[math.random(#tbl)]
end

function table.push(tbl, elem)
  table.insert(tbl, #tbl, elem)
  return elem
end

function table.find(tbl, what)
  local index = nil
  for i, l in pairs(tbl) do
    if l == what then
      index = i
      break
    end
  end
  return index
end

--- Pushes an element to the back of the table (index 1).
--- @param tbl table
--- @param elem any
--- @return any the item you just added
function table.pushback(tbl, elem)
  table.insert(tbl, 1, elem)
  return elem
end

--- Removes an item from the front of a table and returns it.
--- @param tbl table
--- @return any the item you just popped
function table.pop(tbl)
  return table.remove(tbl, #tbl)
end

--- Removes an item from the back (index 1) of a table and returns it.
--- @param tbl table
--- @return any the item you just popped
function table.popback(tbl)
  return table.remove(tbl, 1)
end

--- Returns a table's key values.
--- Only works with tables that have non-index keys.
---
--- May be unordered.
--- @param tbl table
--- @return table<any> but probably table<string>
function table.keys(tbl)
  local keys = {}
  for i, _ in pairs(tbl) do
    table.insert(keys, i)
  end
  return keys
end

--- Copies a table to another.
--- @param tbl table
--- @param seen? table This parameter is not meant to be used, the function calls iself recursively and this parameter is used.
--- @return table
function table.copy(tbl, seen)
  seen = seen or {}
  if seen[tbl] then
    return seen[tbl]
  end
  if type(tbl) ~= "table" then
    return tbl
  end
  local result = {}
  seen[tbl] = result
  for k, v in pairs(tbl) do
    if type(v) == "table" then
      result[k] = table.copy(v, seen)
    else
      result[k] = v
    end
  end
  local mt = getmetatable(tbl)
  if mt then
    setmetatable(result, mt)
  end
  return result
end

--- Merges 2 tables into one
--- @param t1 table
--- @param t2 table
--- @return table
function table.merge(t1, t2)
  local result = {}
  if type(t1) ~= "table" or type(t2) ~= "table" then
    return type(t1) == "table" and t1 or result
  end
  for k, v in pairs(t1) do
    result[k] = v
  end
  for k, v in pairs(t2) do
    result[k] = v
  end
  return result
end

--- Same as table.merge but merges recursive tables.
---
--- So if you have a table inside a table, it will also be merged.
--- @param default table
--- @param override table
function table.deepmerge(default, override)
  local result = table.copy(default)
  for k, v in pairs(override) do
    if Type.isTable(v) and Type.isTable(result[k]) then
      result[k] = table.deepmerge(result[k], v)
    else
      result[k] = v
    end
  end
  return result
end

--- Converts a table to a string
--- @param tbl table
--- @return string Surprisingly base lua doesn't have this for printing so that's why it exists here
function table.tostring(tbl)
  if type(tbl) ~= "table" then return "{nil}" end
  local result = {}
  for k, v in pairs(tbl) do
    local key = type(k) == "string" and k or "[" .. tostring(k) .. "]"
    local value = type(v) == "string" and '"' .. v .. '"' or tostring(v)
    table.insert(result, key .. " = " .. value)
  end
  return tostring(tbl) .. " {\n  " .. table.concat(result, ",\n  ") .. "\n}"
end

--- Same as table.tostring but only with number indexed tables.
--- @param tbl table
--- @return string
function table.arraytostring(tbl)
  local result = {}
  for _, v in ipairs(tbl) do
    if type(v) == "string" then
      table.insert(result, '"' .. v .. '"')
    else
      table.insert(result, tostring(v))
    end
  end
  return tostring(tbl) .. " [\n  " .. table.concat(result, ",\n  ") .. "\n]"
end
