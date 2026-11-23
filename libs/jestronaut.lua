local optionsLib = require "jestronaut/environment/options"
local describeLib = require "jestronaut/environment/describe"
local environmentLib = require "jestronaut/environment"
local coverageLib = require "jestronaut/coverage"
local asyncLib = require "jestronaut/environment/async"
local testLib = require "jestronaut/environment/test"
local discoveryLib = require "jestronaut/discovery"
local expectLib = require "jestronaut/expect"
local mockLib = require "jestronaut/mock"
local setupModuleMocking = mockLib.setupModuleMocking

setupModuleMocking()

--- @class Jestronaut
local JESTRONAUT = {
    version = "0.6-1",
    runnerOptions = {},
}

--- @param runnerOptions RunnerOptions
--- @return Jestronaut
function JESTRONAUT:configure(runnerOptions)
    environmentLib.resetEnvironment()

    -- Setup the root describe
    describeLib.describe("root", function() end)

    runnerOptions = optionsLib.merge(runnerOptions)

    self.runnerOptions = runnerOptions

    if not runnerOptions.roots then
        error(
        "No roots found in config. Provide at least one root that points to a directory where tests will be run from.")
    end

    environmentLib.setRoots(runnerOptions.roots)

    if runnerOptions.coverage == true then
        coverageLib.setupCoverage(runnerOptions.roots, runnerOptions.coverageDirectory, runnerOptions.coverageProvider)
    end

    return self
end

--- Registers the tests, by one of:
--- - calling the given function, which loads the test files (e.g. by requiring them);
--- - loading the given list of test files;
--- - finding the test files in the roots, when nothing is given (see the testMatch option). This requires
---   LuaFileSystem.
--- Test files that fail to load are reported as failing tests.
--- @param testRegistrar? function|string[]
--- @return Jestronaut
function JESTRONAUT:registerTests(testRegistrar)
    if not self.runnerOptions then
        error(
        "No options found. You must setup jestronaut (with jestronaut:configure(options)) before registering tests.")
    end

    if type(testRegistrar) == "function" then
        environmentLib.registerTests(testRegistrar)

        return self
    end

    local testFiles = testRegistrar

    if testFiles == nil then
        testFiles = discoveryLib.findTestFiles(self.runnerOptions)
    elseif type(testFiles) == "string" then
        testFiles = { testFiles }
    elseif type(testFiles) ~= "table" then
        error("registerTests expects a function that loads the tests, a list of test files, or nothing to find the " ..
            "test files in the roots. Got " .. type(testFiles), 2)
    end

    environmentLib.registerTests(function()
        for _, path in ipairs(testFiles) do
            testLib.loadTestFile(path)
        end
    end)

    return self
end

--- Runs the tests, then calls `onFinishedCallback` with the results.
---
--- With the `external` event loop option, tests that wait for asynchronous work continue when `jestronaut:tick()` is
--- called, so this returns before they have finished.
---
--- When a test fails and the `exitOnFailure` option is enabled (the default wherever `os.exit` exists), the
--- process exits with status code 1 after `onFinishedCallback` has been called. This lets CI detect failures.
--- @param onFinishedCallback? fun(results: TestRunResults)
--- @return Jestronaut
function JESTRONAUT:runTests(onFinishedCallback)
    if not self.runnerOptions then
        error("No options found. You must setup jestronaut (with jestronaut:configure(options)) before running tests.")
    end

    local runnerOptions = self.runnerOptions

    environmentLib.runTests(runnerOptions, function(results)
        self.results = results

        if onFinishedCallback then
            onFinishedCallback(results)
        end

        if not results.success and runnerOptions.exitOnFailure ~= false and type(os.exit) == "function" then
            os.exit(1)
        end
    end)

    return self
end

--- Continues running tests that are waiting for asynchronous work, when the eventLoop option has `external` set.
--- Call this regularly from your application's own loop, e.g. every frame.
--- @return boolean # True when no tests are running anymore.
function JESTRONAUT:tick()
    return environmentLib.tick()
end

--- Marks a test or hook function as asynchronous, so it receives a `done` callback to call when it has finished.
--- On Lua 5.2+ and LuaJIT, functions that take a parameter are asynchronous without this. On Lua 5.1 this is needed.
--- @param fn fun(done: fun(err?: any))
--- @return table
function JESTRONAUT:async(fn)
    return asyncLib.markAsync(fn)
end

--- Retries failing tests in the current test file or describe the given number of times. Must be called while
--- registering tests, at the top of a test file or in a describe.
--- @param numRetries number
--- @param options? { logErrorsBeforeRetry?: boolean }
function JESTRONAUT:retryTimes(numRetries, options)
    environmentLib.retryTimes(numRetries, options)
end

--- Sets the default timeout, in milliseconds, for tests and hooks that take a done callback in the current test file or
--- describe. Must be called while registering tests, at the top of a test file or in a describe.
--- @param timeout number
function JESTRONAUT:setTimeout(timeout)
    environmentLib.setTimeout(timeout)
end

function JESTRONAUT:getGlobals()
    local globals = {}

    expectLib.exposeTo(globals)
    environmentLib.exposeTo(globals)

    globals.jestronaut = self

    mockLib.exposeTo(globals.jestronaut)

    return globals
end

function JESTRONAUT:withGlobals()
    local globals = self:getGlobals()

    for key, value in pairs(globals) do
        _G[key] = value
    end
end

package.loaded['@jestronaut_globals'] = JESTRONAUT:getGlobals()

return JESTRONAUT
