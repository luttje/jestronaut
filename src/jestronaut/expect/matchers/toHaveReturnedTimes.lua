--- @param expect Expect
local function toHaveReturnedTimes(expect, times)
  local actual = expect.value

  if not expect:checkEquals(true, actual:hasReturnedTimes(times)) then
    error("Expected " .. tostring(actual) .. " to have returned " .. tostring(times) .. " times")
  end

  return true
end

return {
  toHaveReturnedTimes = toHaveReturnedTimes,
  default = toHaveReturnedTimes,
}