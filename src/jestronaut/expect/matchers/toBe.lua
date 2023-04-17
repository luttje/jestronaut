local tableEquals = require "jestronaut.utils.tables".tableEquals

--- Determines whether two values are the same value. Two values are the same if one of the following holds true:
--- both undefined
--- both null
--- both true or both false
--- both strings of the same length with the same characters in the same order
--- both the same object (meaning both values reference the same object in memory)
--- both BigInts with the same numeric value
--- both symbols that reference the same symbol value
--- both numbers and
---     both +0
---     both -0
---     both NaN
---     or both non-zero, not NaN, and have the same value
--- @param expect Expect
--- @param value any
--- @return boolean
local function toBe(expect, value)
  local actual = expect.value

  if (type(actual) == 'table' and type(actual) == type(value)) then
    if not (tableEquals(actual, value)) then
      error("Expected table " .. table.concat(actual, ', ') .. " to be " .. tostring(value))
    end

    return true
  end

  if not (actual == value) then
    error("Expected " .. tostring(actual) .. " to be " .. tostring(value))
  end

  return true
end

return {
  toBe = toBe,
}