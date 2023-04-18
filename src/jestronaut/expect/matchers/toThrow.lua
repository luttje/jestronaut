local metatableLib = require "jestronaut.utils.metatables"

--- Calls the function and expects it to throw an error.
--- @param expect Expect
--- @param errorOrErrorType any
--- @return boolean
local function toThrow(expect, errorOrErrorType)
  local success, err = pcall(expect.value)

  if not expect:checkEquals(false, success) then
    error('Expected the function to throw an error.')
  end

  if errorOrErrorType ~= nil then
    if type(errorOrErrorType) == "string" then
      local message = tostring((type(err) == 'table' and err.message or err) or err)

      if not expect:checkEquals(true, message:find(errorOrErrorType) ~= nil) then
        error('Expected the function to throw an error of type ' .. tostring(errorOrErrorType) .. ' but it threw an error with message "' .. message .. '".')
      end
    elseif type(errorOrErrorType) == 'table' then
      if not expect:checkEquals(true, errorOrErrorType.constructor and metatableLib.instanceOf(err, errorOrErrorType.constructor) or metatableLib.instanceOf(err, errorOrErrorType)) then
        error("Expected " .. tostring(err) .. " to be an instance of " .. tostring(errorOrErrorType))
      end
    elseif not expect:checkEquals(true, type(err) == errorOrErrorType) then
      error('Expected the function to throw an error of type ' .. tostring(errorOrErrorType) .. ' but it threw an error of type ' .. tostring(type(err)) .. '.')
    end
  end

  return true
end

return {
  toThrow = toThrow,
  default = toThrow,
}