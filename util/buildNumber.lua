local function getBuildNumber()
  local current = 1
  local file = io.open("buildnumber.txt", "a+")
  if file then
    local num = file:read("*a")
    if num:len() == 0 then -- just in case the build number isn't written
      file:write(tostring(current))
    end
    current = tonumber(num) or 1
    file:close()
  end
  -- update build number if its a release build
  local nextBuild = current + 1
  file = io.open("buildnumber.txt", "w")
  if file then
    file:write(tostring(nextBuild))
    file:close()
  end
  return nextBuild, true
end

local leadingNumber = os.date("%y%V")
local buildNum = getBuildNumber()

local versionID = ("%s.%.3i"):format(leadingNumber, buildNum)
return versionID
