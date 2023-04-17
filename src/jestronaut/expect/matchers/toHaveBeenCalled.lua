--- @param expect Expect
local function toHaveBeenCalled(expect)
  local actual = expect.value

  if not (actual:wasCalled()) then
    error("Expected " .. tostring(actual) .. " to have been called")
  end

  return true
end

return {
  toHaveBeenCalled = toHaveBeenCalled,
}