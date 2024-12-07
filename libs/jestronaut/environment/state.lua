local extendMetaTableIndex = require "jestronaut/utils/metatables".extendMetaTableIndex
local contextLib = require "jestronaut/environment/context"
local runnerLib = require "jestronaut/environment/runner"
local stringsLib = require "jestronaut/utils/strings"
local tablesLib = require "jestronaut/utils/tables"

local rootFilePaths

--- @class DescribeOrTest
--- @type DescribeOrTest?
local currentDescribeOrTest = nil

--- All file paths with all tests and describes in the file.
--- @type table<string, {testCopy: DescribeOrTest, registered: DescribeOrTest}[]>
local testFunctionLookup = {}
local testFunctionLookupByRegistered = {}

--- @type DescribeOrTest?
local currentParent = nil

local function resetEnvironment()
    currentDescribeOrTest = nil
    rootFilePaths = nil
    currentParent = nil

    -- TODO: This messes with resetting tests, since beforeAll and such would have to be seen again (require tests again) to function again.
    testFunctionLookup = {}
    testFunctionLookupByRegistered = {}
end

--- Sets where Jestronaut should look for tests. This is used to determine the test file path.
--- @param roots string[]
local function setRoots(roots)
    for i, root in ipairs(roots) do
        roots[i] = stringsLib.normalizePath(root)
    end

    rootFilePaths = roots
end

--- Gets the file path, starting line, and ending line of the test by checking the stack trace
--- until it reaches beyond the root of this package.
--- @param test DescribeOrTest
--- @return string, number, number
local function getTestFilePath(test)
    local filePath, startLineNumber, endLineNumber
    local i = 1

    local testFn = test and test.fn

    if (test and type(testFn) == "table") then
        -- Async tests are wrapped in a table and have the original function stored
        -- for this function, so we can get the file path and line number from the original function
        testFn = testFn.originalFunction
    end

    while true do
        local info = debug.getinfo(testFn or i, "Sl")

        if (not info) then
            error(
                "Could not find the test file path. Please make sure options.roots is set to the directories where your tests are located."
            )

            break
        end

        local path = stringsLib.normalizePath(
            info.source:sub(1, 1) == "@" and info.source:sub(2) or info.source
        )

        if rootFilePaths ~= nil then
            local found = false

            -- Check if the file path contains the root file path. If it does, then we've found the test
            for _, rootFilePath in ipairs(rootFilePaths) do
                if path:sub(1, rootFilePath:len()) == rootFilePath then
                    filePath = path
                    startLineNumber = info.linedefined
                    endLineNumber = info.lastlinedefined
                    found = true
                    break
                end
            end

            if found then
                break
            end
        else
            filePath = path
            startLineNumber = info.linedefined
            endLineNumber = info.lastlinedefined
            break
        end

        if (not testFn) then
            i = i + 1
        else
            testFn = nil
        end
    end

    return filePath, startLineNumber, endLineNumber
end

--- Gets a test (or describe, or either) by checking if the given filePath and line number
--- matches a test function.
--- It will only return the deepest nested test or describe that matches the line number.
--- @param filePath string
--- @param lineNumber number
--- @param shouldGetTestCopy? boolean Defaults to true
--- @param matchOnlyOn "test" | "describe" | "both"
--- @return DescribeOrTest?
local function getByFilePathAndLineNumber(filePath, lineNumber, shouldGetTestCopy, matchOnlyOn)
    filePath = stringsLib.normalizePath(
        filePath:sub(1, 1) == "@" and filePath:sub(2) or filePath
    )

    local testsAndDescribes = testFunctionLookup[filePath]
    local foundTestOrDescribe = nil

    if not testsAndDescribes then
        return nil
    end

    if (shouldGetTestCopy == nil) then
        shouldGetTestCopy = true
    end

    for _, describeOrTestInfo in ipairs(testsAndDescribes) do
        local match = true
        local describeOrTest

        if (shouldGetTestCopy) then
            describeOrTest = describeOrTestInfo.testCopy
            assert(describeOrTest, "Test copy not found for test or describe")
        else
            describeOrTest = describeOrTestInfo.registered
        end

        if matchOnlyOn == "test" then
            match = describeOrTest.isTest
        elseif matchOnlyOn == "describe" then
            match = describeOrTest.isDescribe
        end

        if match and describeOrTest.startLineNumber <= lineNumber and describeOrTest.endLineNumber >= lineNumber then
            -- The last match will be the most nested one, so we'll return that
            foundTestOrDescribe = describeOrTest
        end
    end

    return foundTestOrDescribe
end

--- Gets information about the caller function, such that we can find the
--- file path and line number of the caller for tracking which test we're
--- being called inside of.
--- @return string, number # The file path and line number of the caller
local function getCallerFunctionInfo()
    -- Let's traverse the stack to find the correct caller, starting at 3,
    -- since those are definetely not the caller we want
    local i = 3

    while true do
        local info = debug.getinfo(i, "Sl")

        if (not info) then
            error("Could not find the caller function line.")
        end

        local source = stringsLib.normalizePath(
            info.source:sub(1, 1) == "@" and info.source:sub(2) or info.source
        )

        if rootFilePaths ~= nil then
            -- Check if the file path contains the root file path. If it does, then we've found the test
            for _, rootFilePath in ipairs(rootFilePaths) do
                if source:sub(1, rootFilePath:len()) == rootFilePath then
                    return source, info.currentline
                end
            end
        else
            return source, info.currentline
        end

        i = i + 1
    end
end

--- Gets the test that is being called from the caller function.
--- Optionally takes a matchOnlyOn parameter to only match on describes, tests, or both.
--- @param shouldGetTestCopy? boolean Defaults to true
--- @param matchOnlyOn? "test" | "describe" | "both" Defaults to "test"
--- @return DescribeOrTest?
local function getFromCallerFunction(shouldGetTestCopy, matchOnlyOn)
    local source, lineNumber = getCallerFunctionInfo()
    local describeOrTest = getByFilePathAndLineNumber(source, lineNumber, shouldGetTestCopy, matchOnlyOn or "test")

    return describeOrTest
end

--- Sets the amount of times tests will be retried. Must be called at the top of a file or describe block.
--- @param numRetries number
--- @param options table
local function retryTimes(numRetries, options)
    local relevantDescribe = getFromCallerFunction(false, "describe")

    if relevantDescribe then
        if relevantDescribe.isTest then
            error("Cannot set the test retries outside of a file or describe block", 2)
        end

        relevantDescribe.retrySettings = {
            timesRemaining = numRetries,
            numRetries = numRetries,
            options = options or {},
        }

        print("Setting retries for describe", relevantDescribe.name, numRetries, relevantDescribe.fn)

        return
    end

    local filePath = getTestFilePath(currentDescribeOrTest)
    local testFileContext = contextLib.getTestFileContext(filePath)

    testFileContext.retrySettings = {
        timesRemaining = numRetries,
        numRetries = numRetries,
        options = options or {},
    }
end

local function beforeDescribeOrTest(describeOrTest)
    currentDescribeOrTest = describeOrTest

    -- We check all parents, up to and including the file for context conditions
    -- such as beforeAll for each and call them if not already called in
    -- the current test context
    contextLib.traverseTestContexts(describeOrTest, function(context)
        if (context.beforeAll and not context.beforeAllCalled) then
            context.beforeAllCalled = true
            context.beforeAll()
        end

        if context.beforeEach then
            context.beforeEach()
        end
    end)
end

local function afterDescribeOrTest(describeOrTest, success)
    local fileContext = contextLib.getTestFileContext(describeOrTest.filePath)

    if fileContext.afterEach then
        fileContext.afterEach()
    end

    if fileContext.afterAll then
        fileContext.afterAll()
    end

    currentDescribeOrTest = nil
end

local function setupBeforeAfterCallback(fn, functionName)
    local relevantDescribe = getFromCallerFunction(false, "describe")

    if (relevantDescribe) then
        relevantDescribe[functionName] = fn
    else
        local filePath = getTestFilePath(currentDescribeOrTest)
        local fileContext = contextLib.getTestFileContext(filePath)
        fileContext[functionName] = fn
    end
end

local function afterAll(fn, timeout)
    assert(not timeout, "Timeout is not implemented yet for afterAll")

    setupBeforeAfterCallback(fn, "afterAll")
end

local function afterEach(fn, timeout)
    assert(not timeout, "Timeout is not implemented yet for afterEach")

    setupBeforeAfterCallback(fn, "afterEach")
end

local function beforeAll(fn, timeout)
    assert(not timeout, "Timeout is not implemented yet for beforeAll")

    setupBeforeAfterCallback(fn, "beforeAll")
end

local function beforeEach(fn, timeout)
    assert(not timeout, "Timeout is not implemented yet for beforeEach")

    setupBeforeAfterCallback(fn, "beforeEach")
end

--- @class DescribeOrTest
local DESCRIBE_OR_TEST_META = {
    indentationLevel = -1, -- Start at -1 so the root describe is at 0
    name = "",
    fn = function() end,
    isOnlyToRun = false,
    toSkip = false,

    assertionCount = 0,
    parent = nil,
    childCount = 0,
    childTestCount = 0,
    grandChildrenCount = 0,
    grandChildrenTestCount = 0,

    --- @type DescribeOrTest[]
    children = nil
}

DESCRIBE_OR_TEST_META.__index = DESCRIBE_OR_TEST_META

--- Adds a child describe or test.
--- @param child DescribeOrTest
function DESCRIBE_OR_TEST_META:addChild(child)
    self.childCount = self.childCount + 1

    if child.isTest then
        self.childTestCount = self.childTestCount + 1
    end

    self.children[self.childCount] = child
    self.childrenLookup[child.name] = self.childCount

    child.parent = self

    if self.parent then
        self.parent.grandChildrenCount = self.parent.grandChildrenCount + 1

        if child.isTest then
            self.parent.grandChildrenTestCount = self.parent.grandChildrenTestCount + 1
        end
    end
end

function DESCRIBE_OR_TEST_META:flipIfFailExpected(success, errorMessage)
    if self.expectFail == true then
        if success then
            success = false
            errorMessage = "Error! Expected test to fail, but it succeeded."
        else
            success = true
        end
    end

    return success, errorMessage
end

--- @class DescribeOrTestForRun : DescribeOrTest
local DESCRIBE_OR_TEST_FOR_RUN_META = {
    isDescribeOrTestForRun = true,
}

extendMetaTableIndex(DESCRIBE_OR_TEST_FOR_RUN_META, DESCRIBE_OR_TEST_META)

function DESCRIBE_OR_TEST_FOR_RUN_META:addChild(describeOrTest)
    self.children[#self.children + 1] = describeOrTest

    describeOrTest.parent = self
end

--- Creates a copy of the describe or test for running. Returns the estimated amount of tests to skip.
--- @param describeOrTest DescribeOrTest
--- @param runnerOptions RunnerOptions
--- @return DescribeOrTestForRun, number
local function makeDescribeOrTestForRun(describeOrTest, runnerOptions)
    local describeOrTestForRun = {}

    for key, value in pairs(describeOrTest) do
        if key == "children" then
            value = {}
        elseif key == "parent" then
            value = nil
        end

        describeOrTestForRun[key] = value
    end

    -- Some things to copy that are in the metatable
    describeOrTestForRun.indentationLevel = describeOrTest.indentationLevel
    describeOrTestForRun.isTest = describeOrTest.isTest
    describeOrTestForRun.isDescribe = describeOrTest.isDescribe

    describeOrTestForRun.registered = describeOrTest

    testFunctionLookupByRegistered[describeOrTest].testCopy = describeOrTestForRun

    -- Where context is stored, for things like storing expected assertions
    describeOrTestForRun.context = {
        retrySettings = describeOrTest.retrySettings and tablesLib.copy(describeOrTest.retrySettings),
        beforeAll = describeOrTest.beforeAll,
        beforeEach = describeOrTest.beforeEach,
        afterAll = describeOrTest.afterAll,
        afterEach = describeOrTest.afterEach,
    }

    describeOrTestForRun.traverseTestContexts = function(callback)
        return contextLib.traverseTestContexts(describeOrTestForRun, callback)
    end

    if runnerOptions.testPathIgnorePatterns then
        for _, pattern in ipairs(runnerOptions.testPathIgnorePatterns) do
            local plain = not pattern:find("^/.*/$")          -- Only enable pattern matching if the pattern doesn't start and end with a slash
            pattern = plain and pattern or pattern:sub(2, -2) -- Remove the slashes if pattern matching is enabled

            if describeOrTestForRun.filePath:find(pattern, nil, plain) then
                describeOrTestForRun.toSkip = true
            end
        end
    elseif runnerOptions.testNamePattern then
        if not describeOrTestForRun.name:find(runnerOptions.testNamePattern) then
            describeOrTestForRun.toSkip = true
        end
    end

    setmetatable(describeOrTestForRun, DESCRIBE_OR_TEST_FOR_RUN_META)

    return describeOrTestForRun, (describeOrTestForRun.toSkip and 1 or 0)
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
    skippedCount = 0,
    failedCount = 0,
}

FILE_FOR_RUN.__index = FILE_FOR_RUN

--- Recursively copies a Describe or Test to be run, returning the root describe, a table with all describes grouped by file path,
--- and the number of skipped tests.
--- TODO: This function is a bit of a mess and could be cleaned up. I don't like the way it's handling the file paths.
--- TODO: I later added the bit to cache test file paths and line numbers, and I don't think the original describesByFilePath
--- TODO: table is that useful anymore.
--- @param describeOrTest DescribeOrTest
--- @param runnerOptions RunnerOptions
--- @return DescribeOrTestForRun, table, number
local function copyDescribeOrTestForRun(describeOrTest, runnerOptions)
    assert(
        not describeOrTest.registered,
        "Cannot copy a describe or test is already a copy of a registered test or describe"
    )

    local describeOrTestForRun, skippedTestCount = makeDescribeOrTestForRun(describeOrTest, runnerOptions)
    local describesByFilePath = {}

    local function insertChildWithFile(child)
        local fileIndex = #describesByFilePath + 1

        for i, file in ipairs(describesByFilePath) do
            if file.filePath == child.filePath then
                fileIndex = i
                break
            end
        end

        assert(child.registered, "Provided child is not a copy, but a registered describe or test")
        testFunctionLookupByRegistered[child.registered].testCopy = child

        describesByFilePath[fileIndex] = describesByFilePath[fileIndex] or setmetatable({
            filePath = child.filePath,
            describesOrTests = {},
        }, FILE_FOR_RUN)

        if describesByFilePath[fileIndex].__skipNextAdded then
            child.toSkip = true
            skippedTestCount = skippedTestCount + 1
        end

        if child.isOnlyToRun then
            describesByFilePath[fileIndex].__skipNextAdded = true
        end

        table.insert(describesByFilePath[fileIndex].describesOrTests, child)
    end

    if describeOrTest.children then
        for _, child in pairs(describeOrTest.children) do
            local childCopy, childDescribesByFilePath, childSkippedCount = copyDescribeOrTestForRun(child, runnerOptions)

            describeOrTestForRun:addChild(childCopy)

            skippedTestCount = skippedTestCount + childSkippedCount
        end

        for _, child in pairs(describeOrTestForRun.children) do
            insertChildWithFile(child)
        end
    end

    return describeOrTestForRun, describesByFilePath, skippedTestCount
end

--- Registers a Describe or Test to be run.
--- Must be called once befrore all others with a Describe to set as root.
--- @param describeOrTest DescribeOrTest
local function registerDescribeOrTest(describeOrTest)
    local filePath, startLineNumber, endLineNumber = getTestFilePath(describeOrTest)

    describeOrTest.filePath = filePath
    describeOrTest.startLineNumber = startLineNumber
    describeOrTest.endLineNumber = endLineNumber

    -- Build the lookup for easily finding tests and describes by file, which
    -- is used to find test contexts by file path and line number
    testFunctionLookup[filePath] = testFunctionLookup[filePath] or {}
    local lookupIndex = #testFunctionLookup[filePath] + 1
    testFunctionLookup[filePath][lookupIndex] = {
        testCopy = nil,
        registered = describeOrTest,
    }
    testFunctionLookupByRegistered[describeOrTest] = testFunctionLookup[filePath][lookupIndex]

    if not currentParent then
        assert(describeOrTest.name == "root", "Root describe not set. Use `jestronaut.describe('root', function() end)` to set the root describe.")
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

local function incrementAssertionCount()
    local relevantDescribeOrTest = getFromCallerFunction()

    if not relevantDescribeOrTest then
        error("Cannot increase the assertion count outside of a test or describe block", 2)
    end

    relevantDescribeOrTest.assertionCount = relevantDescribeOrTest.assertionCount + 1
end

local function setExpectAssertion()
    local relevantDescribeOrTest = getFromCallerFunction()

    if not relevantDescribeOrTest then
        error("Cannot set the expect assertion outside of a test or describe block", 2)
    end

    relevantDescribeOrTest.isExpectingAssertion = true
end

local function setExpectedAssertionCount(count)
    local relevantDescribeOrTest = getFromCallerFunction()

    if not relevantDescribeOrTest then
        error("Cannot set the expected assertion count outside of a test or describe block", 2)
    end

    relevantDescribeOrTest.expectedAssertionCount = count
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

--- Runs all registered tests.
--- @param runnerOptions RunnerOptions
local function runTests(runnerOptions)
    assert(currentParent,
        'Root describe not set. Use `jestronaut.describe("root", function() end)` to set the root describe.')

    local runner = runnerLib.newTestRunner(runnerOptions)

    runner:setPreTestCallback(function(test)
        beforeDescribeOrTest(test)
    end)

    runner:setModifyTestResultCallback(function(test, success, errorMessage)
        if (test.expectedAssertionCount ~= nil and test.expectedAssertionCount ~= test.assertionCount) then
            success = false
            errorMessage = "Expected " ..
            test.expectedAssertionCount .. " assertions, but " .. test.assertionCount .. " were run"
        end

        if (test.isExpectingAssertion and test.assertionCount == 0) then
            success = false
            errorMessage = "Expected at least one assertion to be run, but none were run"
        end

        return test:flipIfFailExpected(success, errorMessage)
    end)

    runner:setPostTestCallback(function(test, success)
        afterDescribeOrTest(test, success)
    end)

    local testSetRootCopy, describesByFilePath, skippedTestCount = copyDescribeOrTestForRun(currentParent, runnerOptions)

    local function queueTestIfTest(describeOrTestCopy)
        runner:queueTest(describeOrTestCopy)

        if describeOrTestCopy.children then
            for _, childCopy in ipairs(describeOrTestCopy.children) do
                queueTestIfTest(childCopy)
            end
        end
    end

    -- Find all nested describes and tests and add them to the runner queue
    for _, describeOrTestCopy in ipairs(testSetRootCopy.children) do
        queueTestIfTest(describeOrTestCopy)
    end

    runner:start(testSetRootCopy, describesByFilePath, skippedTestCount)
    runnerOptions.eventLoopTicker(function()
        return runner:tick()
    end)
end

return {
    DESCRIBE_OR_TEST_META = DESCRIBE_OR_TEST_META,
    DESCRIBE_OR_TEST_FOR_RUN_META = DESCRIBE_OR_TEST_FOR_RUN_META,

    resetEnvironment = resetEnvironment,

    getDescribeOrTestForRun = copyDescribeOrTestForRun,
    registerDescribeOrTest = registerDescribeOrTest,

    setRoots = setRoots,
    registerTests = registerTests,
    runTests = runTests,

    incrementAssertionCount = incrementAssertionCount,
    setExpectAssertion = setExpectAssertion,
    setExpectedAssertionCount = setExpectedAssertionCount,

    retryTimes = retryTimes,

    afterAll = afterAll,
    afterEach = afterEach,
    beforeAll = beforeAll,
    beforeEach = beforeEach,
}
