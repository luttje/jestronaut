--- Determines whether two values are the same.
--- @param expect Expect
--- @param value any
--- @return boolean
local function toEqual(expect, value)
  if not (expect.value == value) then
    error("Expected " .. tostring(expect.value) .. " to equal " .. tostring(value))
  end

  return true
end

--- @param expect Expect
local function build(expect, customEqualityTesters)
  -- TODO: customEqualityTesters
  return function(expect, value)
    return toEqual(expect, value)
  end
end

return {
  toEqual = toEqual,
  build = build,
}