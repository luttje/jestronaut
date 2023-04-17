local ASYMETRIC_MATCHER_META = require "jestronaut.expect.asymetricmatchers.asymetricmatcher".ASYMETRIC_MATCHER_META
local extendMetaTableIndex = require "jestronaut.utils.metatables".extendMetaTableIndex
local tableImplode = require "jestronaut.utils.tables".implode

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
      return false
    end

    -- matches any received object that recursively matches the expected properties. That is, the expected object is a subset of the received object. Therefore, it matches a received object which contains properties that are present in the expected object.
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
    return 'Object' .. (self.inverse and 'Not' or '') .. 'Containing: \'' .. tableImplode(self.sample, ', ') .. "'"
  end,

  getExpectedType = function(self)
    return 'table'
  end,
}

extendMetaTableIndex(OBJECT_CONTAINING_META, ASYMETRIC_MATCHER_META)

return {
  OBJECT_CONTAINING_META = OBJECT_CONTAINING_META,
  build = function(expect, customEqualityTesters)
    return function(expect, sample)
      return OBJECT_CONTAINING_META.new(sample, expect.inverse, customEqualityTesters)
    end
  end,
}