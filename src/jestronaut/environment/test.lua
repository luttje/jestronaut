local DESCRIBE_OR_TEST_META = require "jestronaut.environment.shared".DESCRIBE_OR_TEST_META
local registerDescribeOrTest = require "jestronaut.environment.state".registerDescribeOrTest
local extendMetaTableIndex = require "jestronaut.utils.metatables".extendMetaTableIndex

--- @class Test
local TEST_META = {
  isTest = true,

  timeout = 5000,
}

extendMetaTableIndex(TEST_META, DESCRIBE_OR_TEST_META)

--- Creates a new test.
--- @param name string
--- @param fn function
--- @param timeout number
--- @return Test
local function test(name, fn, timeout)
  local test = {
    name = name,
    fn = fn,
    timeout = timeout,
  }

  setmetatable(test, TEST_META)

  registerDescribeOrTest(test)

  return test
end

--- Creates a new test that is the only one that will run.
--- @param test Test
--- @param name string
--- @param fn function
--- @param timeout number
--- @return Test
local function testOnly(test, name, fn, timeout)
  test.isOnly = true
  test(name, fn, timeout)

  return test
end

--- Creates a new test that will be skipped.
--- @param test Test
--- @param name string
--- @param fn function
--- @param timeout number
--- @return Test
local function testSkip(test, name, fn, timeout)
  test.isSkipping = true
  test(name, fn, timeout)

  return test
end

--- Creates a new test that will run concurrently.
--- @param name string
--- @param fn function
--- @param timeout number
--- @return Test
--- @private
local function testConcurrent(name, fn, timeout)
  --- @Not yet implemented
  return {}
end

--- Creates a new test that will run concurrently and is the only one that will run.
--- @param name string
--- @param fn function
--- @param timeout number
--- @return Test
--- @private
local function testConcurrentOnly(name, fn, timeout)
  --- @Not yet implemented
end

--- Creates a new test that will run concurrently and will be skipped.
--- @param name string
--- @param fn function
--- @param timeout number
--- @return Test
--- @private
local function testConcurrentSkip(name, fn, timeout)
  --- @Not yet implemented
end

--- Creates a new test that will fail.
--- @param name string
--- @param fn function
--- @param timeout number
--- @return Test
--- @private
local function testFailing(name, fn, timeout)
  --- @Not yet implemented
end

--- Creates a new test that will fail and is the only one that will run.
--- @param name string
--- @param fn function
--- @param timeout number
--- @return Test
--- @private
local function testFailingOnly(name, fn, timeout)
  --- @Not yet implemented
end

--- Creates a new test that will fail and will be skipped.
--- @param name string
--- @param fn function
--- @param timeout number
--- @return Test
--- @private
local function testFailingSkip(name, fn, timeout)
  --- @Not yet implemented
end

--- Indicates this test is yet to be written.
--- @param name string
--- @return Test
--- @private
local function testTodo(name)
  --- @Not yet implemented
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
}
