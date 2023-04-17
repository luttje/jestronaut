local makeIndexableFunction = require "jestronaut.utils.metatables".makeIndexableFunction
local customEqualityTesters = {}
local customMatchers = {}

local function getModifier(key)
  -- local modifier = require('jestronaut.expect.modifiers.' .. key)
  -- return modifier
  local success, modifier = pcall(require, 'jestronaut.expect.modifiers.' .. key)

  if success then
    return modifier
  end

  return nil
end

local function getMatcher(key)
  if customMatchers[key] then
    return customMatchers[key]
  end

  local success, matcher = pcall(require, 'jestronaut.expect.matchers.' .. key)

  if success then
    return matcher
  end

  return nil
end

--- @class Expect
--- @field value any
--- @field toBe fun(value: any): boolean
--- @field toHaveBeenCalled fun(): boolean
local EXPECT_META = {
  value = nil,

  __index = function(self, key)
    local modifier = getModifier(key)
    if modifier then
      return modifier.build(self)
    end

    local matcher = getMatcher(key)
    if matcher then
      if key == 'toEqual' then
        return matcher.build(self, customEqualityTesters)
      elseif matcher.build ~= nil then
        return matcher.build(self)
      end

      return matcher[key]
    end

    error('Unknown matcher or modifier: ' .. key)
  end
}

local function expect(value)
  local expectInstance = {
    value = value
  }

  setmetatable(expectInstance, EXPECT_META)

  return expectInstance
end

--- Exposes the expect function to the global environment.
--- @param targetEnvironment table
local function exposeTo(targetEnvironment)
  targetEnvironment.expect = makeIndexableFunction(expect, {
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

    stringMatching = require "jestronaut.expect.asymetricmatchers.stringMatching".build(expect),
  })
end

return {
  EXPECT_META = EXPECT_META,
  expect = expect,
  exposeTo = exposeTo,
}