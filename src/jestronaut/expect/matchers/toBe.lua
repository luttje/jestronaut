--- Determines whether two values are the same value. Two values are the same if one of the following holds true:
--- both undefined
--- both null
--- both true or both false
--- both strings of the same length with the same characters in the same order
--- both the same object (meaning both values reference the same object in memory)
--- both BigInts with the same numeric value -- N/a
--- both symbols that reference the same symbol value -- N/a
--- both numbers and
---     both +0
---     both -0
---     both NaN
---     or both non-zero, not NaN, and have the same value
--- @param expect Expect
--- @param expected any
--- @return boolean
local function toBe(expect, expected)
  local actual = expect.value

  if not expect:checkEquals(actual, expected) then
    error("Expected " .. tostring(actual) .. (expect.inverse and " not " or "") .. " to be " .. tostring(expected))
  end

  return true
end

return {
  toBe = toBe,
  default = toBe,
}