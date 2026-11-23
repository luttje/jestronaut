-- Integration checks for runner behaviour that can't be tested from inside a single test run, like the run
-- results, bail and test name filtering. Each check does a complete Jestronaut run over a fixture file in
-- tests/fixtures/ and inspects what happened.
--
-- Run from the root of the repository: `lua tests/integration.lua`
package.path = "./libs/?.lua;" .. package.path
require "jestronaut":withGlobals()

local failures = {}

--- A reporter that prints nothing and records which tests passed, failed or were skipped.
local function newRecordingReporter()
    local recorded = { passed = {}, failed = {}, skipped = {} }
    local reporter = setmetatable({ recorded = recorded }, {
        __index = function()
            return function() end
        end,
    })

    function reporter:testFinished(describeOrTest, success)
        if describeOrTest.isTest then
            table.insert(success and recorded.passed or recorded.failed, describeOrTest.name)
        end
    end

    function reporter:testSkipped(describeOrTest)
        if describeOrTest.isTest then
            table.insert(recorded.skipped, describeOrTest.name)
        end
    end

    return reporter
end

--- Runs the given fixture file with the given options.
--- @param fixture string
--- @param options table
--- @return TestRunResults, table
local function run(fixture, options)
    local reporter = newRecordingReporter()
    local runResults

    options.roots = { "./tests/fixtures/" }
    options.reporter = reporter
    options.exitOnFailure = false

    jestronaut
        :configure(options)
        :registerTests(function()
            dofile("./tests/fixtures/" .. fixture .. ".lua")
        end)
        :runTests(function(results)
            runResults = results
        end)

    return runResults, reporter.recorded
end

local function check(description, actual, expected)
    if type(expected) == "table" then
        table.sort(actual)
        table.sort(expected)
        actual = table.concat(actual, ", ")
        expected = table.concat(expected, ", ")
    end

    if actual ~= expected then
        table.insert(failures,
            description .. "\n    expected: " .. tostring(expected) .. "\n    actual:   " .. tostring(actual))
    end
end

-- Run results
do
    local results = run("bail", {})
    check("results.success is false when a test fails", results.success, false)
    check("results.failedCount counts failed tests", results.failedCount, 3)
    check("results.bailed is false without bail", results.bailed, false)

    results = run("names", {})
    check("results.success is true when all tests pass", results.success, true)
    check("results.failedCount is 0 when all tests pass", results.failedCount, 0)
end

-- Bail
do
    local results, recorded = run("bail", {})
    check("bail defaults to running all tests", #recorded.passed + #recorded.failed, 4)

    results, recorded = run("bail", { bail = false })
    check("bail = false runs all tests", #recorded.passed + #recorded.failed, 4)
    check("bail = false doesn't bail", results.bailed, false)

    results, recorded = run("bail", { bail = true })
    check("bail = true stops after the first failure", results.failedCount, 1)
    check("bail = true reports bailed", results.bailed, true)

    results, recorded = run("bail", { bail = 2 })
    check("bail = 2 stops after the second failure", results.failedCount, 2)
    check("bail = 2 ran up to the second failure", #recorded.passed + #recorded.failed, 2)

    results, recorded = run("bail", { bail = "3" })
    check("bail = '3' (as passed by the CLI) stops after the third failure", results.failedCount, 3)
    check("bail = '3' ran all tests up to the third failure", #recorded.passed + #recorded.failed, 4)
end

-- testNamePattern
do
    local _, recorded = run("names", { testNamePattern = "inner" })
    check("testNamePattern matches test names inside nested describes", recorded.passed,
        { "first inner test", "second inner test" })

    _, recorded = run("names", { testNamePattern = "^outer inner first" })
    check("testNamePattern matches the full name including describe names", recorded.passed, { "first inner test" })

    _, recorded = run("names", { testNamePattern = "^outer outer test$" })
    check("testNamePattern can select a single test in a describe", recorded.passed, { "outer test" })
    check("testNamePattern skips the tests that don't match", recorded.skipped,
        { "top-level test", "first inner test", "second inner test" })

    _, recorded = run("names", { testNamePattern = "^top%-level test$" })
    check("testNamePattern can select a top-level test", recorded.passed, { "top-level test" })

    _, recorded = run("names", { testNamePattern = "inner", testPathIgnorePatterns = { "/does-not-exist/" } })
    check("testNamePattern also works together with testPathIgnorePatterns", recorded.passed,
        { "first inner test", "second inner test" })
end

if #failures > 0 then
    print(#failures .. " integration check(s) failed:\n")

    for _, failure in ipairs(failures) do
        print("  ✗ " .. failure .. "\n")
    end

    os.exit(1)
end

print("All integration checks passed.")
