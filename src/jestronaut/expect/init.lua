local makeIndexableFunction = require "jestronaut.utils.metatables".makeIndexableFunction
local makeFunctionShim = require "jestronaut.utils.functions".makeFunctionShim
local stateLib = require "jestronaut.environment.state"

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


local function getAsymmetricMatcher(key)
  local modulePath = 'jestronaut.expect.asymmetricmatchers.' .. key
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
--- @field actual any
local EXPECT_META = {
  actual = nil,

  checkEquals = function(self, expected, actual)
    if(actual == nil)then
      return self.inverse ~= false
    end

    for _, tester in ipairs(customEqualityTesters) do
      local result = tester(expected, actual)

      if result ~= nil then
        return self.inverse ~= result
      end
    end

    return self.inverse ~= (actual == expected)
  end,
}

EXPECT_META.__index = function(self, key)
  if EXPECT_META[key] ~= nil then
    return EXPECT_META[key]
  end

  if key == 'actual' then
    local selfActual = rawget(self, 'actual')

    if(selfActual and type(selfActual) == 'table' and selfActual.isExpect)then
      local actual = selfActual[key]

      if actual ~= nil then
        return actual
      end
    end

    return selfActual
  end

  local modifier = modifiers[key]

  if modifier then
    return modifier(self)
  end

  local matcher = getMatcher(key)
  if matcher then
    local matcherFunc
    if matcher.build ~= nil then
      matcherFunc = matcher.build(self, customEqualityTesters)
    else
      matcherFunc = matcher.default
    end
    
    return makeFunctionShim(matcherFunc, function(success, ...)
      stateLib.incrementAssertionCount()
    end)
  end

  local asymmetricMatcher = getAsymmetricMatcher(key)
  if asymmetricMatcher then
    if asymmetricMatcher.build ~= nil then
      return asymmetricMatcher.build(self, customEqualityTesters)
    end

    return asymmetricMatcher.default
  end

  error('Unknown (asymmetric) matcher or modifier: ' .. key)
end

function expect(actual)
  local expectInstance = {
    actual = actual,
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

    assertions = function(self, count)
      stateLib.setExpectedAssertionCount(count)
    end,

    hasAssertions = function(self)
      stateLib.setExpectAssertion()
    end,

    extend = function(self, matchers)
      for key, matcher in pairs(matchers) do
        customMatchers[key] = matcher
      end
    end,
  })

  local metaTable = getmetatable(targetEnvironment.expect)
  metaTable.__index = function(self, key)
    -- Create a new expect instance with the expect function as the value (so not the same expect instance is constantly modified)
    return expect(self)[key]
  end
end

return {
  EXPECT_META = EXPECT_META,
  expect = expect,
  exposeTo = exposeTo,
}