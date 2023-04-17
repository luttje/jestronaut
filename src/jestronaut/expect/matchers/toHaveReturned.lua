--- @param expect Expect
local function toHaveReturned(expect)
  local actual = expect.value

  if actual:hasReturned() == expect.inverse then
    error("Expected " .. tostring(actual) .. " to have returned something")
  end

  return true
end

return {
  toHaveReturned = toHaveReturned,
  default = toHaveReturned,
}