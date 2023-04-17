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

  asymmetricMatch = function(self, other)
    print 'ArrayContaining'
    if not (type(self.sample) == 'table') then
      error('ArrayContaining sample must be a table')
    end

    if not (type(other) == 'table') then
      return false
    end

    -- matches a received array which contains all of the elements in the expected array. That is, the expected array is a subset of the received array. Therefore, it matches a received array which contains elements that are not in the expected array.
    local result = true

    for _, expectedElement in ipairs(self.sample) do
      local found = false

      for _, receivedElement in ipairs(other) do
        for _, customEqualityTester in ipairs(self.customEqualityTesters) do
          -- Try raw equality first
          if expectedElement == receivedElement then
            found = true
            break
          elseif customEqualityTester(expectedElement, receivedElement) then
            found = true
            break
          end
        end

        if found then
          break
        end
      end

      if not found then
        result = false
        break
      end
    end

    return self.inverse and not result or result
  end,

  __tostring = function(self)
    return 'Array' .. (self.inverse and 'Not' or '') .. 'Containing'
  end,

  getExpectedType = function(self)
    return 'table'
  end,
}

extendMetaTableIndex(ARRAY_CONTAINING_META, ASYMETRIC_MATCHER_META)

return {
  ARRAY_CONTAINING_META = ARRAY_CONTAINING_META,
  build = function(expect, customEqualityTesters)
    return function(expect, sample, inverse)
      return ARRAY_CONTAINING_META.new(sample, inverse, customEqualityTesters)
    end
  end,
}