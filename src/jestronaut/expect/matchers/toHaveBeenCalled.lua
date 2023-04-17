--- @param expect Expect
local function toHaveBeenCalled(expect)
  local actual = expect.value

  if actual:wasCalled() == expect.inverse then
    error("Expected " .. tostring(actual) .. " to have been called")
  end

  return true
end

return {
  toHaveBeenCalled = toHaveBeenCalled,
  default = toHaveBeenCalled,
}