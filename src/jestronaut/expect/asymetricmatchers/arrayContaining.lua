local ASYMETRIC_MATCHER_META = require "jestronaut.expect.asymetricmatchers.asymetricmatcher".ASYMETRIC_MATCHER_META
local extendMetaTableIndex = require "jestronaut.utils.metatables".extendMetaTableIndex

--- @class ArrayContaining
local ARRAY_CONTAINING_META
ARRAY_CONTAINING_META = {
  customEqualityTesters = nil,

  new = function(sample, inverse, customEqualityTesters)
    local instance = {
      sample = sample,
      inverse = inverse or false,
      customEqualityTesters = customEqualityTesters or {},
    }

    setmetatable(instance, ARRAY_CONTAINING_META)
    return instance
  end,

  asymmetricMatch = function(self, actual)
    if not (type(self.sample) == 'table') then
      error('ArrayContaining sample must be a table')
    end

    if not (type(actual) == 'table') then
      return false
    end

    -- matches a received array which contains all of the elements in the expected array. That is, the expected array is a subset of the received array. Therefore, it matches a received array which contains elements that are not in the expected array.
    local found = {}

    for _, expectedElement in ipairs(self.sample) do
      found[expectedElement] = false
    end

    for _, receivedElement in ipairs(actual) do
      for _, expectedElement in ipairs(self.sample) do
        for _, customEqualityTester in ipairs(self.customEqualityTesters) do
          -- Try raw equality first
          if expectedElement == receivedElement then
            found[expectedElement] = true
            break
          elseif customEqualityTester(expectedElement, receivedElement) then
            found[expectedElement] = true
            break
          end
        end
      end
    end

    for _, foundElement in pairs(found) do
      if not foundElement then
        return self.inverse and true or false
      end
    end

    return self.inverse and false or true
  end,

  __tostring = function(self)
    return 'Array' .. (self.inverse and 'Not' or '') .. 'Containing: \'' .. table.concat(self.sample, ', ') .. "'"
  end,

  getExpectedType = function(self)
    return 'table'
  end,
}

extendMetaTableIndex(ARRAY_CONTAINING_META, ASYMETRIC_MATCHER_META)

return {
  ARRAY_CONTAINING_META = ARRAY_CONTAINING_META,
  build = function(expect, customEqualityTesters)
    return function(expect, sample)
      return ARRAY_CONTAINING_META.new(sample, expect.inverse, customEqualityTesters)
    end
  end,
}