-- Expect metatable for jestronaut, loads these modifiers, matchers and more from the jestronaut.expect.* modules:
-- Modifiers
--     .not
--     .resolves
--     .rejects
-- Matchers
--     .toBe(value)
--     .toHaveBeenCalled()
--     .toHaveBeenCalledTimes(number)
--     .toHaveBeenCalledWith(arg1, arg2, ...)
--     .toHaveBeenLastCalledWith(arg1, arg2, ...)
--     .toHaveBeenNthCalledWith(nthCall, arg1, arg2, ....)
--     .toHaveReturned()
--     .toHaveReturnedTimes(number)
--     .toHaveReturnedWith(value)
--     .toHaveLastReturnedWith(value)
--     .toHaveNthReturnedWith(nthCall, value)
--     .toHaveLength(number)
--     .toHaveProperty(keyPath, value?)
--     .toBeCloseTo(number, numDigits?)
--     .toBeDefined()
--     .toBeFalsy()
--     .toBeGreaterThan(number | bigint)
--     .toBeGreaterThanOrEqual(number | bigint)
--     .toBeLessThan(number | bigint)
--     .toBeLessThanOrEqual(number | bigint)
--     .toBeInstanceOf(Class)
--     .toBeNull()
--     .toBeTruthy()
--     .toBeUndefined()
--     .toBeNaN()
--     .toContain(item)
--     .toContainEqual(item)
--     .toEqual(value)
--     .toMatch(regexp | string)
--     .toMatchObject(object)
--     .toMatchSnapshot(propertyMatchers?, hint?)
--     .toMatchInlineSnapshot(propertyMatchers?, inlineSnapshot)
--     .toStrictEqual(value)
--     .toThrow(error?)
--     .toThrowErrorMatchingSnapshot(hint?)
--     .toThrowErrorMatchingInlineSnapshot(inlineSnapshot)
-- Asymmetric Matchers
--     expect.anything()
--     expect.any(constructor)
--     expect.arrayContaining(array)
--     expect.not.arrayContaining(array)
--     expect.closeTo(number, numDigits?)
--     expect.objectContaining(object)
--     expect.not.objectContaining(object)
--     expect.stringContaining(string)
--     expect.not.stringContaining(string)
--     expect.stringMatching(string | regexp)
--     expect.not.stringMatching(string | regexp)
-- Assertion Count
--     expect.assertions(number)
--     expect.hasAssertions()
-- Extend Utilities
--     expect.addEqualityTesters(testers)
--     expect.addSnapshotSerializer(serializer)
--     expect.extend(matchers)

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

local function getMetatable()
  local metatable = {
    __index = function(self, key)
      local modifier = getModifier(key)
      if modifier then
        return modifier.build(self)
      end

      local matcher = getMatcher(key)
      if matcher then
        if key == 'toEqual' then
          return matcher.build(self, customEqualityTesters)
        end

        return matcher.build(self)
      end

      error('Unknown matcher or modifier: ' .. key)
    end
  }

  return metatable
end

local function expect(value)
  local expectInstance = {
    value = value
  }

  setmetatable(expectInstance, getMetatable())

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
end

return {
  expect = expect,
  exposeTo = exposeTo,
}