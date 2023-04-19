--- Determines whether two values are close to each other.
--- @param expect Expect
--- @param value any
--- @param numDigits number
--- @return boolean
local function toBeCloseTo(expect, value, numDigits)
  local actual = expect.actual
  numDigits = numDigits or 2

  if not expect:checkEquals(true, math.abs(actual - value) < math.pow(10, -numDigits / 2)) then
    error("Expected " .. tostring(actual) .. " to be close to " .. tostring(value) .. " with " .. tostring(numDigits) .. " digits")
  end

  return true
end

return {
  toBeCloseTo = toBeCloseTo,
  default = toBeCloseTo,
}