local makeIndexableFunction = require "jestronaut.utils.metatables".makeIndexableFunction
local customEqualityTesters = {}
local customMatchers = {}
local expect

local modifiers = {
  ["not"] = function(expect)
    expect.inverse = true
    return expect
  end,
}

local function getMatcher(key)
  if customMatchers[key] then
    return customMatchers[key]
  end

  local modulePath = 'jestronaut.expect.matchers.' .. key
  local success, matcherOrError = pcall(require, modulePath)

  if not success then
    if not (matcherOrError:find("^module '" .. modulePath .. "' not found")) then
      error(matcherOrError)
    end

    return nil
  end

  return matcherOrError
end

--- @class Expect
--- @field value any
--- @field toBe fun(value: any): boolean
--- @field toHaveBeenCalled fun(): boolean
local EXPECT_META = {
  value = nil,

  checkEquals = function(self, expected, actual)
    if(actual == nil)then
      return self.inverse ~= false
    end

    return self.inverse ~= (actual == expected)
  end,
}

EXPECT_META.__index = function(self, key)
  if EXPECT_META[key] ~= nil then
    return EXPECT_META[key]
  end

  -- If the value is the expect function, try that first
  if key == 'value' then
    local selfValue = rawget(self, 'value')

    if(selfValue and type(selfValue) == 'table' and selfValue.isExpect)then
      local value = selfValue[key]

      if value ~= nil then
        return value
      end
    end

    return selfValue
  end

  local modifier = modifiers[key]

  if modifier then
    return modifier(self)
  end

  local matcher = getMatcher(key)
  if matcher then
    if matcher.build ~= nil then
      return matcher.build(self, customEqualityTesters)
    end

    return matcher.default
  end

  error('Unknown matcher or modifier: ' .. key)
end

function expect(value)
  local expectInstance = {
    value = value,
    inverse = false,
  }

  setmetatable(expectInstance, EXPECT_META)

  return expectInstance
end

--- Exposes the expect function to the global environment.
--- @param targetEnvironment table
local function exposeTo(targetEnvironment)
  targetEnvironment.expect = makeIndexableFunction(expect, {
    isExpect = true,

    addEqualityTesters = function(self, testers)
      for _, tester in ipairs(testers) do
        table.insert(customEqualityTesters, tester)
      end
    end,

    addSnapshotSerializer = function(self, serializer)
      --- @Not implemented
      -- TODO: You can call expect.addSnapshotSerializer to add a module that formats application-specific data structures.
    end,

    extend = function(self, matchers)
      for key, matcher in pairs(matchers) do
        customMatchers[key] = matcher
      end
    end,
  })

  local metaTable = getmetatable(targetEnvironment.expect)
  metaTable.__index = function(self, key)
    local modifier = modifiers[key]

    if modifier then
      return modifier(self)
    end

    local success, asymmetricMatcher = pcall(require, 'jestronaut.expect.asymmetricmatchers.' .. key)

    if success then
      if asymmetricMatcher.build ~= nil then
        -- Create a new expect instance with the expect function as the value
        local expectInstance = expect(self)
        return asymmetricMatcher.build(expectInstance, customEqualityTesters)
      end

      return asymmetricMatcher.default
    end
  end
end

return {
  EXPECT_META = EXPECT_META,
  expect = expect,
  exposeTo = exposeTo,
}