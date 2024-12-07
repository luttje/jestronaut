local DESCRIBE_OR_TEST_META = require "jestronaut/environment/state".DESCRIBE_OR_TEST_META
local registerDescribeOrTest = require "jestronaut/environment/state".registerDescribeOrTest
local extendMetaTableIndex = require "jestronaut/utils/metatables".extendMetaTableIndex

--- @alias AsyncTestFunction {isAsync: true, testFn: function}
--- @alias TestFunction fun()|AsyncTestFunction

--- @class Test
local TEST_META = {
    isTest = true,

    timeout = 5000,
}

extendMetaTableIndex(TEST_META, DESCRIBE_OR_TEST_META)

--- Wraps a test function to mark it as async.
--- @param testFn function
--- @return AsyncTestFunction
local function wrapAsyncTest(testFn)
    local testWrapper = {
        isAsync = true,
        isDone = false,
        errorMessage = nil,

        -- Keep this, so we can find the file and line numbers for it
        originalFunction = testFn,
    }

    --- Calls the real test function, passing in a done callback.
    --- When the done callback is called, the test is marked as complete.
    --- The runner can check this async wrapper to see if the test is done.
    function testWrapper:testFn()
        local function done(errorMessage)
            self.isDone = true
            self.errorMessage = errorMessage
        end

        testFn(done)
    end

    return testWrapper
end

--- Creates a new test.
--- @param name string
--- @param fn TestFunction
--- @param timeout? number
--- @return Test
local function _internalTest(name, fn, timeout, options)
    if (type(name) ~= "string") then
        error("test name must be a string")
    end

    local test = {
        name = name,
        fn = fn,
        timeout = timeout,
    }

    if options then
        test.isOnlyToRun = options.isOnlyToRun
        test.toSkip = options.toSkip
        test.expectFail = options.expectFail
    end

    setmetatable(test, TEST_META)

    registerDescribeOrTest(test)

    return test
end

--- Creates a new test.
--- @param name string
--- @param fn TestFunction
--- @param timeout? number
--- @return Test
local function test(name, fn, timeout)
    return _internalTest(name, fn, timeout)
end

--- Creates a new test that is the only one that will run.
--- @param self Test
--- @param name string
--- @param fn TestFunction
--- @param timeout? number
--- @return Test
local function testOnly(self, name, fn, timeout)
    local _test = _internalTest(name, fn, timeout, {
        isOnlyToRun = true,
    })

    return _test
end

--- Creates a new test that will be skipped.
--- @param self Test
--- @param name string
--- @param fn TestFunction
--- @param timeout? number
--- @return Test
local function testSkip(self, name, fn, timeout)
    local _test = _internalTest(name, fn, timeout, {
        toSkip = true,
    })

    return _test
end

--- Creates a new test that will run concurrently.
--- @param self Test
--- @param name string
--- @param fn TestFunction
--- @param timeout? number
--- @return Test
--- @private
local function testConcurrent(self, name, fn, timeout)
    --- @Not yet implemented
    return {}
end

--- Creates a new test that will run concurrently and is the only one that will run.
--- @param self Test
--- @param name string
--- @param fn TestFunction
--- @param timeout? number
--- @return Test
--- @private
local function testConcurrentOnly(self, name, fn, timeout)
    --- @Not yet implemented
end

--- Creates a new test that will run concurrently and will be skipped.
--- @param self Test
--- @param name string
--- @param fn TestFunction
--- @param timeout? number
--- @return Test
--- @private
local function testConcurrentSkip(self, name, fn, timeout)
    --- @Not yet implemented
end

--- Creates a new test that will fail.
--- @param self Test
--- @param name string
--- @param fn TestFunction
--- @param timeout? number
--- @return Test
--- @private
local function testFailing(self, name, fn, timeout)
    local _test = _internalTest(name, fn, timeout, {
        expectFail = true,
    })

    return _test
end

--- Creates a new test that will fail and is the only one that will run.
--- @param self Test
--- @param name string
--- @param fn TestFunction
--- @param timeout? number
--- @return Test
--- @private
local function testFailingOnly(self, name, fn, timeout)
    local _test = _internalTest(name, fn, timeout, {
        expectFail = true,
        isOnlyToRun = true,
    })

    return _test
end

--- Creates a new test that will fail and will be skipped.
--- @param self Test
--- @param name string
--- @param fn TestFunction
--- @param timeout? number
--- @return Test
--- @private
local function testFailingSkip(self, name, fn, timeout)
    local _test = _internalTest(name, fn, timeout, {
        expectFail = true,
        toSkip = true,
    })

    return _test
end

--- Indicates this test is yet to be written.
--- @param self Test
--- @param name string
--- @param fn TestFunction
--- @return Test
--- @private
local function testTodo(self, name, fn)
    if fn ~= nil then
        error("test.todo cannot have an implementation")
    end

    local test = {
        name = name,
    }

    test.toSkip = true
    test.isTodo = true

    setmetatable(test, TEST_META)

    registerDescribeOrTest(test)

    return test
end

return {
    test = test,

    testOnly = testOnly,
    ftest = testOnly,

    testSkip = testSkip,
    xtest = testSkip,

    testConcurrent = testConcurrent,
    testConcurrentOnly = testConcurrentOnly,
    testConcurrentSkip = testConcurrentSkip,

    testFailing = testFailing,
    testFailingOnly = testFailingOnly,
    testFailingSkip = testFailingSkip,

    testTodo = testTodo,

    wrapAsyncTest = wrapAsyncTest,
}
