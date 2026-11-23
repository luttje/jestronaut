local optionsLib = require "jestronaut/environment/options"
local describeLib = require "jestronaut/environment/describe"
local environmentLib = require "jestronaut/environment"
local coverageLib = require "jestronaut/coverage"
local asyncLib = require "jestronaut/environment/async"
local expectLib = require "jestronaut/expect"
local mockLib = require "jestronaut/mock"
local setupModuleMocking = mockLib.setupModuleMocking

setupModuleMocking()

--- @class Jestronaut
local JESTRONAUT = {
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

--- Registers the tests. This is done by calling the given function.
--- @param testRegistrar function
--- @return Jestronaut
function JESTRONAUT:registerTests(testRegistrar)
    if not self.runnerOptions then
        error(
        "No options found. You must setup jestronaut (with jestronaut:configure(options)) before registering tests.")
    end

    environmentLib.registerTests(testRegistrar)

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

function JESTRONAUT:retryTimes(numRetries, options)
    environmentLib.retryTimes(numRetries, options)
end

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
