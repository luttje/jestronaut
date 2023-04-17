--- @param expect Expect
--- @param ... any
local function toHaveReturnedWith(expect, ...)
  local actual = expect.value

  if not expect:checkEquals(true, actual:hasReturnedWith(...)) then
    error("Expected " .. tostring(actual) .. " to have returned with " .. tostring(...) .. " but it returned with " .. tostring(actual:getLastReturn()))
  end

  return true
end

return {
  toHaveReturnedWith = toHaveReturnedWith,
  default = toHaveReturnedWith,
}