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

    -- Record which tests will be skipped from the planned tree, since skipped describes are reported as a whole
    function reporter:startTestSet(rootDescribe)
        local function collect(describeOrTest)
            if describeOrTest.isTest and describeOrTest.toSkip then
                table.insert(recorded.skipped, describeOrTest.name)
            end

            for _, child in ipairs(describeOrTest.children or {}) do
                collect(child)
            end
        end

        collect(rootDescribe)
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

--- Like check, but compares lists in order.
local function checkSequence(description, actual, expected)
    actual = table.concat(actual or {}, "\n      ")
    expected = table.concat(expected, "\n      ")

    if actual ~= expected then
        table.insert(failures,
            description .. "\n    expected:\n      " .. expected .. "\n    actual:\n      " .. actual)
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

-- Hook order and scoping
do
    run("hooks", {})
    checkSequence("hooks run once per scope, in the same order as Jest", HOOK_LOG, {
        "file beforeAll",
        "file beforeEach", "top", "file afterEach",
        "outer beforeAll",
        "file beforeEach", "outer beforeEach 1", "outer beforeEach 2", "outer test", "outer afterEach",
        "file afterEach",
        "inner beforeAll",
        "file beforeEach", "outer beforeEach 1", "outer beforeEach 2", "inner beforeEach", "inner test",
        "inner afterEach", "outer afterEach", "file afterEach",
        "inner afterAll", "outer afterAll", "file afterAll",
    })

    run("wrapper", {})
    checkSequence("file level hooks only apply to tests in their own file, even when wrapped in a describe",
        WRAPPER_LOG, {
            "wrapper beforeEach", "wrapper test",
            "wrapper beforeEach", "wrapped file beforeEach", "wrapped test",
            "wrapper beforeEach", "wrapped file beforeEach", "deeply wrapped test",
        })
end

-- Failing hooks
do
    local results, recorded = run("hook-errors", {})
    check("a failing beforeAll fails all tests in its scope, a failing beforeEach or afterEach fails its test",
        recorded.failed, {
            "first test in failing beforeAll", "second test in failing beforeAll",
            "test with failing beforeEach", "test with failing afterEach",
        })
    check("tests without failing hooks still pass", recorded.passed, { "test without failing hooks" })
    check("results count tests failed by hooks", results.failedCount, 4)
    checkSequence("tests don't run when their beforeAll or beforeEach failed, afterEach still runs after beforeEach",
        HOOK_ERRORS_LOG, { "afterEach after failing beforeEach" })
end

-- Retries
do
    local _, recorded = run("retries", {})
    check("each test gets its own retries", recorded.passed, { "passes on the third attempt", "passes on the second attempt" })
    check("tests that keep failing fail after their retries", recorded.failed, { "always fails", "fails without retrying" })
    check("a test is attempted once plus the number of retries", RETRY_ATTEMPTS.always, 3)
    check("retryTimes in a describe overrides retryTimes for the file", RETRY_ATTEMPTS.noRetry, 1)
end

-- only
do
    local _, recorded = run("only", {})
    check("only runs the tests marked only (or in a describe marked only) in that file", recorded.passed,
        { "fails on incorrect modifier only to run", "runs because its describe is marked only" })
    check("only skips the other tests in that file", recorded.skipped,
        { "top-level test without only", "skips failing test", "not run" })
end

-- Counts (issue #10)
do
    local expectedCounts = { totalCount = 8, passedCount = 4, failedCount = 1, skippedCount = 2, todoCount = 1 }

    for _, fixture in ipairs({ "counts", "counts-wrapped" }) do
        local results = run(fixture, {})

        for key, expected in pairs(expectedCounts) do
            check(fixture .. ": results." .. key .. " counts tests at any depth", results[key], expected)
        end
    end
end

if #failures > 0 then
    print(#failures .. " integration check(s) failed:\n")

    for _, failure in ipairs(failures) do
        print("  ✗ " .. failure .. "\n")
    end

    os.exit(1)
end

print("All integration checks passed.")
