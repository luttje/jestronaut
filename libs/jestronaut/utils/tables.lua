local asymmetricMatcherLib = require "jestronaut/expect/asymmetricmatchers/asymmetricmatcher"
local split = require "jestronaut/utils/strings".split

local function equals(objectA, objectB, ignoreMetatable)
  if asymmetricMatcherLib.isMatcher(objectA) then
    return asymmetricMatcherLib.matches(objectA, objectB)
  elseif asymmetricMatcherLib.isMatcher(objectB) then
    return asymmetricMatcherLib.matches(objectB, objectA)
  elseif objectA == objectB then
    return true
  end

  local typeOfObjectA = type(objectA)
  local typeOfObjectB = type(objectB)

  if typeOfObjectA ~= typeOfObjectB then return false end
  if typeOfObjectA ~= 'table' then return false end

  if not ignoreMetatable then
      local mt1 = getmetatable(objectA)
      if mt1 and mt1.__eq then
          --compare using built in method
          return objectA == objectB
      end
  end

  local keySet = {}

  for key1, value1 in pairs(objectA) do
      local value2 = objectB[key1]
      if value2 == nil or equals(value1, value2, ignoreMetatable) == false then
          return false
      end
      keySet[key1] = true
  end

  for key2, _ in pairs(objectB) do
      if not keySet[key2] then return false end
  end

  return true
end

local function count(tbl)
  local count = 0
  for _ in pairs(tbl) do count = count + 1 end
  return count
end

local function keys(tbl)
  local keys = {}
  for k, _ in pairs(tbl) do table.insert(keys, k) end
  return keys
end

local function implode(t, sep, withKeys, depth)
  withKeys = withKeys == nil and true or withKeys
  depth = depth or 0
  sep = sep or ''
  local s = ''
  for k, v in pairs(t) do
    local value = tostring(v)
    if type(v) == 'table' then
      if depth < 5 then
        value = '(table:' .. implode(v, sep, withKeys, depth + 1) .. ')'
      end
    end
    s = s .. (withKeys and (tostring(k) .. '=') or '') .. value .. sep
  end

  return tostring(s:gsub(sep .. '$', ''))
end

local function copy(t1)
  local t = {}

  for k, v in pairs(t1) do
    if type(v) == 'table' then
      t[k] = copy(v)
    else
      t[k] = v
    end
  end

  return t
end

--- Access a table by a path like 'livingroom.amenities[1].couch[1][2].dimensions[1]'
--- @param tbl table
--- @param propertyPath string|table
--- @return any
local function accessByPath(tbl, propertyPath)
  if (type(propertyPath) == 'string') then
    propertyPath = split(propertyPath, '.')
  end

  local newPropertyPath = {}
  
  for _, key in ipairs(propertyPath) do
    if type(key) == 'string' then
      local propertyBeforeIndex = key:match("([^%[]*)%[") or key
      
      table.insert(newPropertyPath, propertyBeforeIndex)

      -- Handle double indexed properties
      while key:find("%[%d+%]") do
        local indexedKey = key:match("%[([^%[%]]+)%]")
        table.insert(newPropertyPath, tonumber(indexedKey))
        key = key:gsub("%[" .. indexedKey .. "%]", "")
      end
    else
      table.insert(newPropertyPath, key)
    end
  end

  propertyPath = newPropertyPath

  local currentActual = tbl

  for _, key in ipairs(propertyPath) do
    currentActual = currentActual[key]
  end

  return currentActual
end

local function isSubset(subset, superset)
  for key, value in pairs(subset) do
    if not (superset[key] ~= nil) then
      return false
    end

    if asymmetricMatcherLib.isMatcher(value) then
      if not asymmetricMatcherLib.matches(value, superset[key]) then
        return false
      end
    else
      if type(value) == 'table' then
        if not isSubset(value, superset[key]) then
          return false
        end
      else
        if not (superset[key] == value) then
          return false
        end
      end
    end
  end

  return true
end

local function contains(tbl, values)
  for _, value in ipairs(values) do
    local found = false

    for _, tblValue in ipairs(tbl) do
      if equals(tblValue, value) then
        found = true
        break
      end
    end

    if not found then
      return false
    end
  end

  return true
end

return {
  equals = equals,
  count = count,
  keys = keys,
  implode = implode,
  copy = copy,
  accessByPath = accessByPath,
  isSubset = isSubset,
  contains = contains,
}