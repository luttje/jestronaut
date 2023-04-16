local DESCRIBE_OR_TEST_META = require "jestronaut.environment.shared".DESCRIBE_OR_TEST_META

--- @class Test
local TEST_META = {
  __index = DESCRIBE_OR_TEST_META,

  timeout = 5000,
}

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

  return test
end

--- Creates a new test that is the only one that will run.
--- @param name string
--- @param fn function
--- @param timeout number
--- @return Test
local function testOnly(name, fn, timeout)
  local test = test(name, fn, timeout)
  test.only = true

  return test
end

--- Creates a new test that will be skipped.
--- @param name string
--- @param fn function
--- @param timeout number
--- @return Test
local function testSkip(name, fn, timeout)
  local test = test(name, fn, timeout)
  test.skip = true

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
  it = test,

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
