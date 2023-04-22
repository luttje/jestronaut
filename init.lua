package.path = package.path .. ";./src/?.lua"
require "jestronaut":withGlobals()

jestronaut:configure({
  -- First make sure all your tests have registered (describe and it/test blocks have been called). Afterwards set the 
  -- roots below, so Jestronaut knows how to recognize test files.
  roots = {
    "./src/tests/",
    "./src/generated-tests/",
  },

  -- Jestronaut will automatically ignore any files listed here. If the path starts and ends with / it will be treated as a Lua pattern.
  testPathIgnorePatterns = {
    "/generated%-tests/ExpectAPI/toBeCloseTo.lua$/", -- This test fails because of floating point errors (the example in Jest docs is meant to fail)
    "/generated%-tests/GlobalAPI/test.lua$/", -- This test fails because of async not being supported

    -- Fake timer functions not supported yet:
    "generated-tests/JestObjectAPI/jest/useFakeTimers.lua",
    "generated-tests/JestObjectAPI/jest/useRealTimers.lua",

    "generated-tests/JestObjectAPI/jest/retryTimes.lua", -- These tests are intended to fail

    "generated-tests/MockFunctionAPI/mockFn/mockName.lua", -- The docs have mockFn commented, causing this test to fail.
    "generated-tests/GlobalAPI/test/failing.lua", -- This test succeeds, but it's supposed to fail
    "generated-tests/GlobalAPI/test/failing/each.lua", -- This test succeeds, but it's supposed to fail
  },

  -- Set to true to show every test result, false to keep output compact.
  -- verbose = true,

  -- Slow down the tests by x milliseconds to make it easier to follow the output.
  slowDown = 200,
}):registerTests(function()
  -- Setup and register the tests:
  require "generated-tests"
  require "tests"
end):runTests()