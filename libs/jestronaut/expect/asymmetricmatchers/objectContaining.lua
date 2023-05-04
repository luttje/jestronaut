local asymmetricMatcherLib = require "jestronaut/expect/asymmetricmatchers/asymmetricmatcher"
local extendMetaTableIndex = require "jestronaut/utils/metatables".extendMetaTableIndex
local tableLib = require "jestronaut/utils/tables"

--- @class ObjectContaining
local OBJECT_CONTAINING_META
OBJECT_CONTAINING_META = {
  customEqualityTesters = nil,

  new = function(sample, inverse, customEqualityTesters)
    local instance = {
      sample = sample,
      inverse = inverse or false,
      customEqualityTesters = customEqualityTesters or {},
    }

    setmetatable(instance, OBJECT_CONTAINING_META)
    return instance
  end,

  asymmetricMatch = function(self, actual)
    if not (type(self.sample) == 'table') then
      error('ObjectContaining sample must be a table')
    end

    if not (type(actual) == 'table') then
      error('ObjectContaining actual value to test must be a table')
    end
    
    local foundAll = true

    for key, value in pairs(self.sample) do
      if not (actual[key] ~= nil) then
        foundAll = false
        break
      end

      if asymmetricMatcherLib.isMatcher(value) then
        if not asymmetricMatcherLib.matches(value, actual[key]) then
          foundAll = false
          break
        end
      else
        if not (actual[key] == value) then
          foundAll = false
          break
        end
      end
    end

    return self.inverse and not foundAll or foundAll
  end,

  __tostring = function(self)
    return 'Object' .. (self.inverse and 'Not' or '') .. 'Containing: \'' .. tableLib.implode(self.sample, ', ') .. "'"
  end,

  getExpectedType = function(self)
    return 'table'
  end,
}

extendMetaTableIndex(OBJECT_CONTAINING_META, asymmetricMatcherLib.ASYMMETRIC_MATCHER_META)

return {
  OBJECT_CONTAINING_META = OBJECT_CONTAINING_META,
  build = function(expect, customEqualityTesters)
    return function(expect, sample)
      return OBJECT_CONTAINING_META.new(sample, expect.inverse, customEqualityTesters)
    end
  end,
}