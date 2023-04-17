--- @param expect Expect
--- @param nthReturned number
--- @param ... any
local function toHaveNthReturnedWith(expect, nthReturned, ...)
  local actual = expect.value

  if actual:hasNthReturnedWith(nthReturned, ...) == expect.inverse then
    error("Expected " .. tostring(actual) .. " to have returned with " .. tostring(...) .. " but it returned with " .. tostring(actual:getLastReturn()))
  end

  return true
end

return {
  toHaveNthReturnedWith = toHaveNthReturnedWith,
  default = toHaveNthReturnedWith,
}