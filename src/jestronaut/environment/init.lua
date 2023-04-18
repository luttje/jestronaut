local makeIndexableFunction = require "jestronaut.utils.metatables".makeIndexableFunction
local describeLib = require "jestronaut.environment.describe"
local testLib = require "jestronaut.environment.test"
local eachLib = require "jestronaut.each"

local environmentOptions = {}
local fileTestTimeouts = {}

-- Setup the root describe
describeLib.describe("root", function() end)

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

-- Set the default timeout interval (in milliseconds) for all tests and before/after hooks in the test file. This only affects the test file from which this function is called. The default timeout interval is 5 seconds if this method is not called.
local function setTimeout(timeout)
  local file = debug.getinfo(2, "S").source:sub(2)
  fileTestTimeouts[file] = timeout
end

local function setRetryTimes(numRetries, options)
  environmentOptions = options or {}
  environmentOptions.numRetries = numRetries
end

--- Exposes the environment functions to the global environment.
--- @param targetEnvironment table
local function exposeTo(targetEnvironment)
  targetEnvironment.afterAll = afterAll
  targetEnvironment.afterEach = afterEach

  targetEnvironment.beforeAll = beforeAll
  targetEnvironment.beforeEach = beforeEach

  targetEnvironment.describe = makeIndexableFunction(function(blockName, blockFn) return describeLib.describe(blockName, blockFn) end)

  targetEnvironment.describe.only = makeIndexableFunction(function(mainDescribe, blockName, blockFn) return describeLib.describeOnly(mainDescribe, blockName, blockFn) end)
  targetEnvironment.describe.skip = makeIndexableFunction(function(mainDescribe, blockName, blockFn) return describeLib.describeSkip(mainDescribe, blockName, blockFn) end)

  eachLib.bindTo(targetEnvironment.describe)
  eachLib.bindTo(targetEnvironment.describe.only)
  eachLib.bindTo(targetEnvironment.describe.skip)

  -- Refactored so both test and it can be used
  local aliases = {'test', 'it'}

  for _, alias in ipairs(aliases) do
    targetEnvironment[alias] = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.test(blockName, blockFn, timeout) end)
    targetEnvironment[alias].concurrent = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.testConcurrent(blockName, blockFn, timeout) end)
    targetEnvironment[alias].concurrent.only = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.testConcurrentOnly(blockName, blockFn, timeout) end)
    targetEnvironment[alias].concurrent.skip = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.testConcurrentSkip(blockName, blockFn, timeout) end)
    targetEnvironment[alias].failing = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.testFailing(blockName, blockFn, timeout) end)
    targetEnvironment[alias].failing.only = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.testFailingOnly(blockName, blockFn, timeout) end)
    targetEnvironment[alias].failing.skip = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.testFailingSkip(blockName, blockFn, timeout) end)
    targetEnvironment[alias].only = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.testOnly(blockName, blockFn, timeout) end)
    targetEnvironment[alias].skip = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.testSkip(blockName, blockFn, timeout) end)
    targetEnvironment[alias].todo = function(blockName) return testLib.testTodo(blockName) end

    eachLib.bindTo(targetEnvironment[alias])
    eachLib.bindTo(targetEnvironment[alias].concurrent)
    eachLib.bindTo(targetEnvironment[alias].concurrent.only)
    eachLib.bindTo(targetEnvironment[alias].concurrent.skip)
    eachLib.bindTo(targetEnvironment[alias].failing)
    eachLib.bindTo(targetEnvironment[alias].failing.only)
    eachLib.bindTo(targetEnvironment[alias].failing.skip)
    eachLib.bindTo(targetEnvironment[alias].only)
    eachLib.bindTo(targetEnvironment[alias].skip)
  end
end

return {
  afterAll = afterAll,
  afterEach = afterEach,

  beforeAll = beforeAll,
  beforeEach = beforeEach,

  setTimeout = setTimeout,
  setRetryTimes = setRetryTimes,
  exposeTo = exposeTo,

  assertions = assertions,
}