--- @param expect Expect
local function toHaveReturned(expect)
  local actual = expect.actual

  if not expect:checkEquals(true, actual:hasReturned()) then
    error("Expected " .. tostring(actual) .. " to have returned something")
  end

  return true
end

return {
  toHaveReturned = toHaveReturned,
  default = toHaveReturned,
}