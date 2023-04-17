--- @param expect Expect
local function toHaveBeenCalledTimes(expect, times)
  local actual = expect.value

  if actual:wasCalledTimes(times) == expect.inverse then
    error("Expected " .. tostring(actual) .. " to have been called")
  end

  return true
end

return {
  toHaveBeenCalledTimes = toHaveBeenCalledTimes,
  default = toHaveBeenCalledTimes,
}