local unpack = table.unpack or unpack

local callRespectingRequireOverride = require "jestronaut/utils/require".callRespectingRequireOverride
local extendMetaTableIndex = require "jestronaut/utils/metatables".extendMetaTableIndex
local functionLib = require "jestronaut/utils/functions"
local stringsLib = require "jestronaut/utils/strings"

local rootFilePaths

--- The test that is currently running. Nil while tests are being registered.
--- @type DescribeOrTest?
local currentDescribeOrTest = nil

--- The describe that tests, describes and hooks are currently being registered in.
--- @type DescribeOrTest?
local currentParent = nil

--- Number of tests that failed so far during the current run, used to decide when to bail.
local totalFailedTestCount = 0

--- Errors of beforeAll hooks that failed during the current run, by hook entry.
local failedBeforeAllHooks = {}

--- Thrown (and caught by runTests) to stop the run when the bail threshold is reached.
local BAIL_SIGNAL_META = {
    __tostring = function(self)
        return self.message
    end,
}

local HOOK_KINDS = { "beforeAll", "beforeEach", "afterAll", "afterEach" }

local function getCurrentDescribeOrTest()
    return currentDescribeOrTest
end

local function resetEnvironment()
    currentDescribeOrTest = nil
    rootFilePaths = nil
    currentParent = nil
end

--- Sets where Jestronaut should look for tests. This is used to determine the test file path.
--- @param roots string[]
local function setRoots(roots)
    for i, root in ipairs(roots) do
        roots[i] = stringsLib.normalizePath(root)
    end

    rootFilePaths = roots
end

--- Gets the file path and line number of the test by checking the stack trace until it reaches beyond the root of this package.
--- @return string, number
local function getTestFilePath()
    local filePath, lineNumber
    local i = 1

    while true do
        local info = debug.getinfo(i, "Sl")

        if (not info) then
            error(
            "Could not find the test file path. Please make sure options.roots is set to the directories where your tests are located.")
            break
        end

        local path = stringsLib.normalizePath(info.source:sub(1, 1) == "@" and info.source:sub(2) or info.source)

        if rootFilePaths ~= nil then
            local found = false

            -- Check if the file path contains the root file path. If it does, then we've found the test
            for _, rootFilePath in ipairs(rootFilePaths) do
                if path:sub(1, rootFilePath:len()) == rootFilePath then
                    filePath = path
                    lineNumber = info.currentline
                    found = true
                    break
                end
            end

            if found then
                break
            end
        else
            filePath = path
            lineNumber = info.currentline
            break
        end

        i = i + 1
    end

    return filePath, lineNumber
end

--- Error handler for xpcall that adds a stack trace to the error.
--- @param err any
--- @return string
local function traceErrorHandler(err)
    -- debug.traceback returns non-string errors (e.g. error({ code = 1 })) untouched, which reporters can't print
    if type(err) ~= "string" then
        err = "(error object is a " .. type(err) .. " value: " .. tostring(err) .. ")"
    end

    return debug.traceback(err, 2)
end

--[[
    Scopes

    Hooks (beforeAll, beforeEach, afterAll, afterEach) and retry settings belong to the describe they are registered
    in. When registered at the top of a test file, they belong to whatever describe that file was required in (usually
    the root describe). Like in Jest, such file level registrations only apply to tests in that same file. Otherwise
    wrapping `require` calls in a describe would let the hooks of one file leak into the tests of others.
--]]

--- Gets the describe that hooks and settings registered right now belong to, and the file they are registered from.
--- @param kind string The name of the function being called, for error messages.
--- @return DescribeOrTest, string
local function getRegistrationScope(kind)
    if currentDescribeOrTest then
        error(kind .. " cannot be called inside a test. Call it at the top of a test file or inside a describe block.", 4)
    end

    if not currentParent then
        error(kind .. " must be called while registering tests (in the function passed to jestronaut:registerTests).", 4)
    end

    local filePath = getTestFilePath()

    return currentParent, filePath
end

--- Creates an entry that remembers where something was registered, so we can check which tests it applies to.
--- @param kind string
--- @return table
local function newScopedEntry(kind)
    local scope, filePath = getRegistrationScope(kind)

    return {
        kind = kind,
        scope = scope,
        filePath = filePath,
        isFileScoped = filePath ~= scope.filePath,
    }, scope
end

--- Checks whether the given describe is an ancestor of the given (registered, not copied for run) test.
--- @param describe DescribeOrTest
--- @param test DescribeOrTest
--- @return boolean
local function isAncestor(describe, test)
    local parent = test.parent

    while parent do
        if parent == describe then
            return true
        end

        parent = parent.parent
    end

    return false
end

--- Checks whether a scoped entry (hook or retry setting) applies to the given (registered) test.
--- @param entry table
--- @param test DescribeOrTest
--- @return boolean
local function appliesTo(entry, test)
    if entry.isFileScoped and entry.filePath ~= test.filePath then
        return false
    end

    return isAncestor(entry.scope, test)
end

--- Registers a hook in the current scope.
--- @param kind string
--- @param fn function
local function registerHook(kind, fn)
    if type(fn) ~= "function" then
        error(kind .. " expects a function, got " .. type(fn), 3)
    end

    local entry, scope = newScopedEntry(kind)
    entry.fn = fn

    if not rawget(scope, "hooks") then
        scope.hooks = { beforeAll = {}, beforeEach = {}, afterAll = {}, afterEach = {} }
    end

    table.insert(scope.hooks[kind], entry)
end

local function afterAll(fn, timeout)
    registerHook("afterAll", fn)
end

local function afterEach(fn, timeout)
    registerHook("afterEach", fn)
end

local function beforeAll(fn, timeout)
    registerHook("beforeAll", fn)
end

local function beforeEach(fn, timeout)
    registerHook("beforeEach", fn)
end

--- Sets how many times failing tests in the current scope (file or describe) are retried.
--- Settings in a describe take precedence over those of surrounding describes and the file.
--- @param numRetries number
--- @param options? { logErrorsBeforeRetry?: boolean }
local function retryTimes(numRetries, options)
    if type(numRetries) ~= "number" or numRetries < 0 then
        error("retryTimes expects a non-negative number of retries, got " .. tostring(numRetries), 3)
    end

    local entry, scope = newScopedEntry("retryTimes")
    entry.times = numRetries
    entry.options = options or {}

    if not rawget(scope, "retrySettings") then
        scope.retrySettings = {}
    end

    table.insert(scope.retrySettings, entry)
end

--- Finds the retry settings of the nearest scope that applies to the given (registered) test.
--- @param test DescribeOrTest
--- @return table?
local function findRetrySettings(test)
    local parent = test.parent

    while parent do
        local found

        for _, entry in ipairs(rawget(parent, "retrySettings") or {}) do
            if appliesTo(entry, test) then
                found = entry -- The last registered setting in a scope wins
            end
        end

        if found then
            return found
        end

        parent = parent.parent
    end
end

local function incrementAssertionCount()
    if not currentDescribeOrTest then
        error("Cannot increase the assertion count outside of a test or describe block", 2)
    end

    currentDescribeOrTest.assertionCount = currentDescribeOrTest.assertionCount + 1
end

local function getAssertionCount()
    if not currentDescribeOrTest then
        error("Cannot get the assertion count outside of a test or describe block", 2)
    end

    return currentDescribeOrTest.assertionCount
end

local function setExpectAssertion()
    if not currentDescribeOrTest then
        error("Cannot set the expect assertion outside of a test or describe block", 2)
    end

    currentDescribeOrTest.expectAssertion = true
end

local function getExpectedAssertionCount()
    if not currentDescribeOrTest then
        error("Cannot get the expected assertion count outside of a test or describe block", 2)
    end

    return currentDescribeOrTest.expectedAssertionCount
end

local function setExpectedAssertionCount(count)
    if not currentDescribeOrTest then
        error("Cannot set the expected assertion count outside of a test or describe block", 2)
    end

    currentDescribeOrTest.expectedAssertionCount = count
end

--- @class DescribeOrTest
local DESCRIBE_OR_TEST_META = {
    indentationLevel = 0,
    name = "",
    fn = function() end,
    isOnlyToRun = false,
    toSkip = false,

    assertionCount = 0,
    parent = nil,
    childCount = 0,
    grandChildrenCount = 0,

    --- @type DescribeOrTest[]
    children = nil
}

DESCRIBE_OR_TEST_META.__index = DESCRIBE_OR_TEST_META

--- Adds a child describe or test.
--- @param child DescribeOrTest
function DESCRIBE_OR_TEST_META:addChild(child)
    self.childCount = self.childCount + 1

    self.children[self.childCount] = child
    self.childrenLookup[child.name] = self.childCount

    child.parent = self

    if self.parent then
        self.parent.grandChildrenCount = self.parent.grandChildrenCount + 1
    end
end

--- Runs a single hook, returning false and an error message if it failed.
--- @param entry table
--- @return boolean, string?
local function runHook(entry)
    local success, err = xpcall(entry.fn, traceErrorHandler)

    if not success then
        return false, entry.kind .. " hook failed: " .. tostring(err)
    end

    return true
end

--- Runs one attempt of a test: its beforeEach hooks, the test itself and its afterEach hooks.
--- Returns whether the attempt succeeded and the errors if it didn't.
--- @return boolean, table
function DESCRIBE_OR_TEST_META:runAttempt()
    currentDescribeOrTest = self

    self.assertionCount = 0
    self.expectedAssertionCount = nil
    self.expectAssertion = nil

    local success, errors = true, {}

    local function addError(err)
        if success then
            success = false
            errors = { err }
        else
            table.insert(errors, "\n" .. tostring(err))
        end
    end

    -- When a beforeAll hook for this test failed, the test fails without running
    for _, entry in ipairs(self.beforeAllHooks) do
        if failedBeforeAllHooks[entry] then
            addError(failedBeforeAllHooks[entry])
            break
        end
    end

    local beforeAllFailed = not success

    if success then
        for _, entry in ipairs(self.beforeEachHooks) do
            local hookSuccess, err = runHook(entry)

            if not hookSuccess then
                addError(err)
                break
            end
        end
    end

    if success then
        local testSuccess, results = functionLib.captureSafeCallInTable(xpcall(self.fn, traceErrorHandler))

        if not testSuccess then
            success = false
            errors = results
        end
    end

    -- Like Jest, afterEach hooks also run when the test or a beforeEach hook failed
    if not beforeAllFailed then
        for _, entry in ipairs(self.afterEachHooks) do
            local hookSuccess, err = runHook(entry)

            if not hookSuccess then
                addError(err)
            end
        end
    end

    if success then
        if self.expectedAssertionCount ~= nil and self.expectedAssertionCount ~= self.assertionCount then
            addError("Expected " .. self.expectedAssertionCount .. " assertions, but " .. self.assertionCount ..
                " were run")
        elseif self.expectAssertion and self.assertionCount == 0 then
            addError("Expected at least one assertion to be run, but none were run")
        end
    end

    if self.expectFail == true then
        if success then
            success = false
            errors = { "Error! Expected test to fail, but it succeeded." }
        else
            success = true
            errors = {}
        end
    end

    currentDescribeOrTest = nil

    return success, errors
end

--- Runs the test, including retries and the beforeAll and afterAll hooks that start or end at this test.
--- Returns the amount of failed tests (0 or 1).
--- @param reporter Reporter
--- @param runnerOptions RunnerOptions
--- @return number
function DESCRIBE_OR_TEST_META:runTest(reporter, runnerOptions)
    currentDescribeOrTest = self

    for _, entry in ipairs(self.beforeAllHooksToRun) do
        local success, err = runHook(entry)

        if not success then
            failedBeforeAllHooks[entry] = err
        end
    end

    local retrySettings = self.retrySettings
    local retriesRemaining = retrySettings and retrySettings.times or 0
    local success, errors

    while true do
        success, errors = self:runAttempt()

        if success or retriesRemaining <= 0 then
            break
        end

        retriesRemaining = retriesRemaining - 1

        if retrySettings.options.logErrorsBeforeRetry then
            reporter:testFinished(self, false, unpack(errors))
        end

        reporter:testRetrying(self, retriesRemaining + 1)
    end

    currentDescribeOrTest = self

    for _, entry in ipairs(self.afterAllHooksToRun) do
        local hookSuccess, err = runHook(entry)

        if not hookSuccess then
            if success then
                success = false
                errors = { err }
            else
                table.insert(errors, "\n" .. tostring(err))
            end
        end
    end

    currentDescribeOrTest = nil

    self.success = success
    self.isRunning = false
    self.hasRun = true
    self.errors = (not success) and errors or nil

    reporter:testFinished(self, success, unpack(errors))

    if success then
        return 0
    end

    totalFailedTestCount = totalFailedTestCount + 1

    if runnerOptions.bail > 0 and totalFailedTestCount >= runnerOptions.bail then
        error(setmetatable({
            message = "Bail after " .. totalFailedTestCount .. " failed " ..
                (totalFailedTestCount == 1 and "test" or "tests") .. " with error: \n" .. tostring(errors[1]),
        }, BAIL_SIGNAL_META))
    end

    return 1
end

--- Runs the describe or test and returns the amount of failed tests.
--- @param reporter Reporter
--- @param runnerOptions RunnerOptions
--- @return number
function DESCRIBE_OR_TEST_META:run(reporter, runnerOptions)
    if self.toSkip then
        reporter:testSkipped(self)

        return 0
    end

    if (runnerOptions.slowDown) then -- For debugging terminal output
        local endTime = os.clock() + runnerOptions.slowDown * 0.001

        -- Start a loop to freeze for the specified amount of milliseconds
        while os.clock() < endTime do end
    end

    reporter:testStarting(self)
    self.isRunning = true

    if self.isTest then
        return self:runTest(reporter, runnerOptions)
    end

    local failedTestCount = 0

    for _, child in ipairs(self.children) do
        failedTestCount = failedTestCount + child:run(reporter, runnerOptions)
    end

    self.isRunning = false
    self.hasRun = true
    self.success = failedTestCount == 0

    reporter:testFinished(self, self.success)

    return failedTestCount
end

--- @class DescribeOrTestForRun : DescribeOrTest
--- @field registered DescribeOrTest The describe or test as it was registered.
local DESCRIBE_OR_TEST_FOR_RUN_META = {
    isDescribeOrTestForRun = true,
}

extendMetaTableIndex(DESCRIBE_OR_TEST_FOR_RUN_META, DESCRIBE_OR_TEST_META)

function DESCRIBE_OR_TEST_FOR_RUN_META:addChild(describeOrTest)
    self.children[#self.children + 1] = describeOrTest
end

--- @class FileForRun
local FILE_FOR_RUN = {
    isFileForRun = true,

    filePath = "",

    --- @type DescribeOrTestForRun[]
    describesOrTests = nil,

    hasRun = false,
    success = false,
    isRunning = false,
    isSkipped = false,
    skippedCount = 0,
    failedCount = 0,
}

FILE_FOR_RUN.__index = FILE_FOR_RUN

--- Gets the name of a (registered) describe or test prefixed with the names of its parent describes, separated by
--- spaces. The root describe (which has no parent) is left out.
--- @param describeOrTest DescribeOrTest
--- @return string
local function getFullName(describeOrTest)
    local names = { describeOrTest.name }
    local parent = describeOrTest.parent

    while parent and parent.parent do
        table.insert(names, 1, parent.name)
        parent = parent.parent
    end

    return table.concat(names, " ")
end

--- Checks whether the (registered) describe or test, or any describe around it, has the given field set.
--- @param describeOrTest DescribeOrTest
--- @param field string
--- @return boolean
local function hasFlagInSelfOrAncestors(describeOrTest, field)
    local current = describeOrTest

    while current do
        if current[field] then
            return true
        end

        current = current.parent
    end

    return false
end

--- Checks whether the file path matches any of the patterns. Patterns that start and end with a slash are treated
--- as Lua patterns, all others are matched as plain text.
--- @param filePath string
--- @param patterns string[]?
--- @return boolean
local function isPathIgnored(filePath, patterns)
    for _, pattern in ipairs(patterns or {}) do
        local plain = not pattern:find("^/.*/$")
        pattern = plain and pattern or pattern:sub(2, -2)

        if filePath:find(pattern, nil, plain) then
            return true
        end
    end

    return false
end

--- Creates a copy of the registered tree for running, so run state doesn't end up in the registrations.
--- @param describeOrTest DescribeOrTest
--- @param parentForRun DescribeOrTestForRun?
--- @return DescribeOrTestForRun
local function copyForRun(describeOrTest, parentForRun)
    local copy = {}

    for key, value in pairs(describeOrTest) do
        copy[key] = value
    end

    copy.registered = describeOrTest
    copy.parent = parentForRun
    copy.indentationLevel = describeOrTest.indentationLevel
    copy.isTest = describeOrTest.isTest
    copy.isDescribe = describeOrTest.isDescribe

    setmetatable(copy, DESCRIBE_OR_TEST_FOR_RUN_META)

    if describeOrTest.isDescribe then
        copy.children = {}

        for _, child in ipairs(describeOrTest.children) do
            copy:addChild(copyForRun(child, copy))
        end
    end

    return copy
end

--- Collects all tests in the tree, in the order they will run.
--- @param describeOrTest DescribeOrTestForRun
--- @param tests? DescribeOrTestForRun[]
--- @return DescribeOrTestForRun[]
local function collectTests(describeOrTest, tests)
    tests = tests or {}

    if describeOrTest.isTest then
        table.insert(tests, describeOrTest)
    elseif describeOrTest.children then
        for _, child in ipairs(describeOrTest.children) do
            collectTests(child, tests)
        end
    end

    return tests
end

--- Marks describes as skipped when none of the tests inside them will run. Returns whether anything inside runs.
--- @param describeOrTest DescribeOrTestForRun
--- @return boolean
local function markSkippedDescribes(describeOrTest)
    if describeOrTest.isTest then
        return not describeOrTest.toSkip
    end

    local anyRuns = false

    for _, child in ipairs(describeOrTest.children) do
        if markSkippedDescribes(child) then
            anyRuns = true
        end
    end

    describeOrTest.toSkip = not anyRuns

    return anyRuns
end

--- Decides which tests will be skipped, based on skip/todo/only and the runner options.
--- @param tests DescribeOrTestForRun[]
--- @param runnerOptions RunnerOptions
local function decideSkippedTests(tests, runnerOptions)
    -- Like Jest, `only` works per file: when a file has tests or describes marked `only`, the others in it are skipped
    local filesWithOnly = {}

    for _, test in ipairs(tests) do
        local current = test.registered

        while current do
            if current.isOnlyToRun then
                filesWithOnly[current.filePath] = true
            end

            current = current.parent
        end
    end

    for _, test in ipairs(tests) do
        local registered = test.registered
        local toSkip = hasFlagInSelfOrAncestors(registered, "toSkip")
            or isPathIgnored(test.filePath, runnerOptions.testPathIgnorePatterns)

        -- Like Jest, only tests are filtered by name, matching against the full name (including the names of
        -- surrounding describe blocks).
        if not toSkip and runnerOptions.testNamePattern then
            toSkip = not getFullName(registered):find(runnerOptions.testNamePattern)
        end

        if not toSkip and filesWithOnly[test.filePath] then
            toSkip = not hasFlagInSelfOrAncestors(registered, "isOnlyToRun")
        end

        test.toSkip = toSkip
    end
end

--- Works out for each test which hooks and retry settings apply to it, and which beforeAll and afterAll hooks
--- should run before and after it. Only tests that will actually run are considered, so beforeAll and afterAll run
--- around the first and last test in their scope that runs, and not at all if none run.
--- @param testSetRoot DescribeOrTestForRun
--- @param tests DescribeOrTestForRun[]
local function planHooks(testSetRoot, tests)
    local runnableTests = {}

    for _, test in ipairs(tests) do
        test.beforeAllHooks = {}
        test.beforeAllHooksToRun = {}
        test.afterAllHooksToRun = {}
        test.beforeEachHooks = {}
        test.afterEachHooks = {}
        test.retrySettings = findRetrySettings(test.registered)

        if not test.toSkip then
            table.insert(runnableTests, test)
        end
    end

    -- Visit describes outer to inner, so hooks of outer describes end up first
    local describesInOrder = {}

    local function collectDescribes(describeOrTest, depth)
        if describeOrTest.isDescribe then
            table.insert(describesInOrder, { describe = describeOrTest.registered, depth = depth })

            for _, child in ipairs(describeOrTest.children) do
                collectDescribes(child, depth + 1)
            end
        end
    end

    collectDescribes(testSetRoot, 0)

    local afterAllCandidates = {}
    local order = 0

    for _, describeInfo in ipairs(describesInOrder) do
        local hooks = rawget(describeInfo.describe, "hooks")

        if hooks then
            for _, entry in ipairs(hooks.beforeAll) do
                local isFirst = true

                for _, test in ipairs(runnableTests) do
                    if appliesTo(entry, test.registered) then
                        table.insert(test.beforeAllHooks, entry)

                        if isFirst then
                            table.insert(test.beforeAllHooksToRun, entry)
                            isFirst = false
                        end
                    end
                end
            end

            for _, entry in ipairs(hooks.afterAll) do
                local lastTest

                for _, test in ipairs(runnableTests) do
                    if appliesTo(entry, test.registered) then
                        lastTest = test
                    end
                end

                if lastTest then
                    order = order + 1
                    table.insert(afterAllCandidates, {
                        test = lastTest, entry = entry, depth = describeInfo.depth, order = order,
                    })
                end
            end
        end
    end

    -- afterAll hooks of inner describes run before those of outer describes
    table.sort(afterAllCandidates, function(a, b)
        if a.depth ~= b.depth then
            return a.depth > b.depth
        end

        return a.order < b.order
    end)

    for _, candidate in ipairs(afterAllCandidates) do
        table.insert(candidate.test.afterAllHooksToRun, candidate.entry)
    end

    -- beforeEach hooks run outer to inner, afterEach hooks inner to outer
    for _, test in ipairs(runnableTests) do
        local ancestors = {}
        local parent = test.registered.parent

        while parent do
            table.insert(ancestors, 1, parent)
            parent = parent.parent
        end

        for _, ancestor in ipairs(ancestors) do
            local hooks = rawget(ancestor, "hooks")

            if hooks then
                for _, entry in ipairs(hooks.beforeEach) do
                    if appliesTo(entry, test.registered) then
                        table.insert(test.beforeEachHooks, entry)
                    end
                end
            end
        end

        for i = #ancestors, 1, -1 do
            local hooks = rawget(ancestors[i], "hooks")

            if hooks then
                for _, entry in ipairs(hooks.afterEach) do
                    if appliesTo(entry, test.registered) then
                        table.insert(test.afterEachHooks, entry)
                    end
                end
            end
        end
    end
end

--- Groups the top level describes and tests by the file they were registered in, for reporters.
--- @param testSetRoot DescribeOrTestForRun
--- @return FileForRun[]
local function groupByFilePath(testSetRoot)
    local describesByFilePath = {}
    local filesByPath = {}

    for _, child in ipairs(testSetRoot.children) do
        local file = filesByPath[child.filePath]

        if not file then
            file = setmetatable({
                filePath = child.filePath,
                describesOrTests = {},
                isSkipped = true,
            }, FILE_FOR_RUN)

            filesByPath[child.filePath] = file
            table.insert(describesByFilePath, file)
        end

        if not child.toSkip then
            file.isSkipped = false
        end

        table.insert(file.describesOrTests, child)
    end

    return describesByFilePath
end

--- Prepares the registered tests for running.
--- @param rootDescribe DescribeOrTest
--- @param runnerOptions RunnerOptions
--- @return DescribeOrTestForRun, FileForRun[], DescribeOrTestForRun[]
local function prepareRun(rootDescribe, runnerOptions)
    local testSetRoot = copyForRun(rootDescribe)
    local tests = collectTests(testSetRoot)

    decideSkippedTests(tests, runnerOptions)
    markSkippedDescribes(testSetRoot)
    planHooks(testSetRoot, tests)

    return testSetRoot, groupByFilePath(testSetRoot), tests
end

--- Counts the outcome of the tests.
--- @param tests DescribeOrTestForRun[]
--- @return table
local function countTests(tests)
    local counts = { total = #tests, passed = 0, failed = 0, skipped = 0, todo = 0 }

    for _, test in ipairs(tests) do
        if test.isTodo then
            counts.todo = counts.todo + 1
        elseif test.toSkip then
            counts.skipped = counts.skipped + 1
        elseif test.hasRun then
            if test.success then
                counts.passed = counts.passed + 1
            else
                counts.failed = counts.failed + 1
            end
        end
    end

    return counts
end

--- Registers a Describe or Test to be run.
--- Must be called once befrore all others with a Describe to set as root.
--- @param describeOrTest DescribeOrTest
local function registerDescribeOrTest(describeOrTest)
    if currentDescribeOrTest then
        error("Cannot register a describe or test while a test is running. Register it at the top of a test file or "
            .. "inside a describe block.", 4)
    end

    local filePath, lineNumber = getTestFilePath()

    describeOrTest.filePath = filePath
    describeOrTest.lineNumber = lineNumber

    if not currentParent then
        currentParent = describeOrTest
    else
        currentParent:addChild(describeOrTest)
    end

    describeOrTest.indentationLevel = currentParent and currentParent.indentationLevel + 1 or 0

    if describeOrTest.isDescribe then
        local oldParent = currentParent
        currentParent = describeOrTest

        describeOrTest.fn()

        currentParent = oldParent
    end

    return describeOrTest
end

--- Registers the tests
--- @param testRegistrar function
local function registerTests(testRegistrar)
    if not rootFilePaths then
        error(
        "No root directory paths have been set. Configure options.roots using jestronaut:config(options) before registering tests.")
    end

    testRegistrar()
end

--- @class TestRunResults
--- @field success boolean # True if no test failed and the run did not bail.
--- @field bailed boolean # True if the run stopped early because of the `bail` option.
--- @field totalCount number # All tests, including skipped and todo tests.
--- @field passedCount number
--- @field failedCount number
--- @field skippedCount number # Skipped tests, not including todo tests.
--- @field todoCount number
--- @field duration number # In seconds.

--- Runs all registered tests.
--- @param runnerOptions RunnerOptions
--- @return TestRunResults
local function runTests(runnerOptions)
    -- Pass modified require's on through
    local reporter = callRespectingRequireOverride(function()
        return runnerOptions.reporter or (require "jestronaut/reporter".newDefaultReporter())
    end)

    reporter.isVerbose = runnerOptions.verbose

    -- currentParent is the root describe at this point
    local testSetRoot, describesByFilePath, tests = prepareRun(currentParent, runnerOptions)
    local initialCounts = countTests(tests)

    -- Reporters use these to show the totals
    testSetRoot.totalTestCount = initialCounts.total
    testSetRoot.todoCount = initialCounts.todo

    reporter:startTestSet(testSetRoot, describesByFilePath)

    totalFailedTestCount = 0
    failedBeforeAllHooks = {}

    local startTime = os.clock()
    local success, err = pcall(testSetRoot.run, testSetRoot, reporter, runnerOptions)
    local endTime = os.clock()

    currentDescribeOrTest = nil

    local counts = countTests(tests)
    local bailed = false

    if not success then
        if getmetatable(err) ~= BAIL_SIGNAL_META then
            error(err, 0)
        end

        bailed = true
        reporter:printBailed(testSetRoot, tostring(err))
    else
        reporter:printEnd(testSetRoot, counts.failed, counts.skipped, endTime - startTime)
    end

    return {
        success = counts.failed == 0 and not bailed,
        bailed = bailed,
        totalCount = counts.total,
        passedCount = counts.passed,
        failedCount = counts.failed,
        skippedCount = counts.skipped,
        todoCount = counts.todo,
        duration = endTime - startTime,
    }
end

return {
    DESCRIBE_OR_TEST_META = DESCRIBE_OR_TEST_META,
    DESCRIBE_OR_TEST_FOR_RUN_META = DESCRIBE_OR_TEST_FOR_RUN_META,
    HOOK_KINDS = HOOK_KINDS,

    resetEnvironment = resetEnvironment,

    getCurrentDescribeOrTest = getCurrentDescribeOrTest,
    getFullName = getFullName,

    registerDescribeOrTest = registerDescribeOrTest,
    setRoots = setRoots,
    registerTests = registerTests,
    runTests = runTests,

    incrementAssertionCount = incrementAssertionCount,
    getAssertionCount = getAssertionCount,
    setExpectAssertion = setExpectAssertion,
    getExpectedAssertionCount = getExpectedAssertionCount,
    setExpectedAssertionCount = setExpectedAssertionCount,

    retryTimes = retryTimes,

    afterAll = afterAll,
    afterEach = afterEach,
    beforeAll = beforeAll,
    beforeEach = beforeEach,
}
