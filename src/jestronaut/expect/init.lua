local makeIndexableFunction = require "jestronaut.utils.metatables".makeIndexableFunction
local customEqualityTesters = {}
local customMatchers = {}

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
  inverse = false,
  value = nil,

  __index = function(self, key)
    local meta = getmetatable(self)
    
    if meta and meta[key] ~= nil then
      return meta[key]
    end

    local modifier = modifiers[key]

    if modifier then
      return modifier(self)
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
  })

  local metaTable = getmetatable(targetEnvironment.expect)
  metaTable.__index = function(tbl, key)
    local success, asymetricMatcher = pcall(require, 'jestronaut.expect.asymetricmatchers.' .. key)

    if success then
      if asymetricMatcher.build ~= nil then
        return asymetricMatcher.build(tbl, customEqualityTesters)
      end

      return asymetricMatcher[key]
    end
  end
end

return {
  EXPECT_META = EXPECT_META,
  expect = expect,
  exposeTo = exposeTo,
}