--- Determines whether two values are the same.
--- @param expect Expect
--- @param value any
--- @return boolean
local function toEqual(expect, value)
  return expect.value == value
end

--- @param expect Expect
local function build(expect)
  return function(value)
    return toEqual(expect, value)
  end
end

return {
  toEqual = toEqual,
  build = build,
}