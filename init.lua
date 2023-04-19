package.path = package.path .. ";./src/?.lua"
require "jestronaut":withGlobals()

jestronaut:configure({
  -- First make sure all your tests have registered (describe and it/test blocks have been called). Afterwards set the 
  -- roots below, so Jestronaut knows how to recognize test files.
  roots = {
    "./src/tests/",
    "./src/generated-tests/",
  },
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
  }
}):registerTests(function()
  -- Setup and register the tests:
  require "tests"
  require "generated-tests"
end):runTests()