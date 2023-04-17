--- @param expect Expect
local function toHaveBeenCalledTimes(expect, times)
  local actual = expect.value

  if not expect:checkEquals(true, actual:wasCalledTimes(times)) then
    error("Expected " .. tostring(actual) .. " to have been called")
  end

  return true
end

return {
  toHaveBeenCalledTimes = toHaveBeenCalledTimes,
  default = toHaveBeenCalledTimes,
}