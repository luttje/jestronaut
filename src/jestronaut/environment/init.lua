local eachLib = require "jestronaut.each"
local describeLib = require "jestronaut.environment.describe"
local testLib = require "jestronaut.environment.test"
local makeIndexableFunction = require "jestronaut.utils.metatables".makeIndexableFunction

--[[
  Library that provides the following functions:
  afterAll(fn, timeout)
  afterEach(fn, timeout)
  beforeAll(fn, timeout)
  beforeEach(fn, timeout)
  describe(name, fn)
  describe.each(table)(name, fn, timeout)
  describe.only(name, fn)
  describe.only.each(table)(name, fn)
  describe.skip(name, fn)
  describe.skip.each(table)(name, fn)
  test(name, fn, timeout)
  test.concurrent(name, fn, timeout)
  test.concurrent.each(table)(name, fn, timeout)
  test.concurrent.only.each(table)(name, fn)
  test.concurrent.skip.each(table)(name, fn)
  test.each(table)(name, fn, timeout)
  test.failing(name, fn, timeout)
  test.failing.each(name, fn, timeout)
  test.only.failing(name, fn, timeout)
  test.skip.failing(name, fn, timeout)
  test.only(name, fn, timeout)
  test.only.each(table)(name, fn)
  test.skip(name, fn)
  test.skip.each(table)(name, fn)
  test.todo(name)
]]

-- Runs a function after all the tests in this file have completed. If the function returns a promise or is a generator, Jest waits for that promise to resolve before continuing.
local function afterAll(fn, timeout)
  --- @Not yet implemented
end

local function afterEach(fn, timeout)
  --- @Not yet implemented
end

local function beforeAll(fn, timeout)
  --- @Not yet implemented
end

local function beforeEach(fn, timeout)
  --- @Not yet implemented
end

--- Exposes the environment functions to the global environment.
--- @param targetEnvironment table
local function exposeTo(targetEnvironment)
  targetEnvironment.afterAll = function(fn, timeout) return afterAll(fn, timeout) end
  targetEnvironment.afterEach = function(fn, timeout) return afterEach(fn, timeout) end

  targetEnvironment.beforeAll = function(fn, timeout) return beforeAll(fn, timeout) end
  targetEnvironment.beforeEach = function(fn, timeout) return beforeEach(fn, timeout) end

  targetEnvironment.describe = makeIndexableFunction(function(blockName, blockFn) return describeLib.describe(blockName, blockFn) end)

  targetEnvironment.describe.only = makeIndexableFunction(function(blockName, blockFn) return describeLib.describeOnly(blockName, blockFn) end)
  targetEnvironment.describe.skip = makeIndexableFunction(function(blockName, blockFn) return describeLib.describeSkip(blockName, blockFn) end)

  eachLib.bindTo(targetEnvironment.describe)
  eachLib.bindTo(targetEnvironment.describe.only)
  eachLib.bindTo(targetEnvironment.describe.skip)

  targetEnvironment.test = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.test(blockName, blockFn, timeout) end)
  targetEnvironment.test.concurrent = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.testConcurrent(blockName, blockFn, timeout) end)
  targetEnvironment.test.concurrent.only = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.testConcurrentOnly(blockName, blockFn, timeout) end)
  targetEnvironment.test.concurrent.skip = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.testConcurrentSkip(blockName, blockFn, timeout) end)
  targetEnvironment.test.failing = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.testFailing(blockName, blockFn, timeout) end)
  targetEnvironment.test.failing.only = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.testFailingOnly(blockName, blockFn, timeout) end)
  targetEnvironment.test.failing.skip = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.testFailingSkip(blockName, blockFn, timeout) end)
  targetEnvironment.test.only = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.testOnly(blockName, blockFn, timeout) end)
  targetEnvironment.test.skip = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.testSkip(blockName, blockFn, timeout) end)
  targetEnvironment.test.todo = function(blockName) return testLib.testTodo(blockName) end

  eachLib.bindTo(targetEnvironment.test)
  eachLib.bindTo(targetEnvironment.test.concurrent)
  eachLib.bindTo(targetEnvironment.test.concurrent.only)
  eachLib.bindTo(targetEnvironment.test.concurrent.skip)
  eachLib.bindTo(targetEnvironment.test.failing)
  eachLib.bindTo(targetEnvironment.test.failing.only)
  eachLib.bindTo(targetEnvironment.test.failing.skip)
  eachLib.bindTo(targetEnvironment.test.only)
  eachLib.bindTo(targetEnvironment.test.skip)
end

return {
  afterAll = afterAll,
  afterEach = afterEach,

  beforeAll = beforeAll,
  beforeEach = beforeEach,

  exposeTo = exposeTo,
}