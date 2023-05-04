local tableLib = require "jestronaut/utils/tables"
local stringLib = require "jestronaut/utils/strings"

--- check if property at provided reference keyPath exists for an object. For checking deeply nested properties in an object you may use dot notation or an array containing the keyPath for deep references.
--- You can provide an optional value argument to compare the received property value (recursively for all properties of object instances, also known as deep equality, like the toEqual matcher).
--- @param expect Expect
--- @param propertyPath string|table
--- @param value any
--- @return boolean
local function toHaveProperty(expect, propertyPath, value)
  local actual = expect.actual

  if (type(actual) ~= 'table') then
    error("Expected " .. tostring(actual) .. " to be a table")
  end
  
  if (type(propertyPath) == 'string') then
    propertyPath = stringLib.split(propertyPath, '.')
  elseif (type(propertyPath) ~= 'table') then
    error("Expected " .. tostring(propertyPath) .. " to be a string or table")
  end

  local propertyString = stringLib.implodePath(propertyPath)

  if tableLib.accessByPath(actual, propertyPath) then
    if value then
      local foundValue = type(value) == 'table' and tableLib.equals(value, tableLib.accessByPath(actual, propertyPath)) 
        or value == tableLib.accessByPath(actual, propertyPath)

      if not expect:checkEquals(foundValue, true) then
        error("Expected " .. tostring(actual) .. " to have property " .. propertyString .. " with value " .. tostring(value) .. " but it was " .. tostring(tableLib.accessByPath(actual, propertyPath)))
      end
    end
  elseif not expect:checkEquals(true) then
    error("Expected " .. tostring(actual) .. " to have property " .. propertyString)
  end

  return true
end

return {
  toHaveProperty = toHaveProperty,
  default = toHaveProperty,
}