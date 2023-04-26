package.path = "./src/?.lua;" .. package.path -- Try our local version first
local jestronaut = require "jestronaut"

jestronaut
  :configure({
    -- First make sure all your tests have registered (describe and it/test blocks have been called). Afterwards set the 
    -- roots below, so Jestronaut knows how to recognize test files.
    roots = {
      "./tests/",
      "./tests/generated",
    },

    -- Jestronaut will automatically ignore any files listed here. If the path starts and ends with / it will be treated as a Lua pattern.
    testPathIgnorePatterns = {
      "/tests/generated/ExpectAPI/toBeCloseTo.lua$/", -- This test fails because of floating point errors (the example in Jest docs is meant to fail)
      "/tests/generated/GlobalAPI/test.lua$/", -- This test fails because of async not being supported

      -- Fake timer functions not supported yet:
      "tests/generated/JestObjectAPI/jest/useFakeTimers.lua",
      "tests/generated/JestObjectAPI/jest/useRealTimers.lua",

      "tests/generated/JestObjectAPI/jest/retryTimes.lua", -- These tests are intended to fail

      "tests/generated/MockFunctionAPI/mockFn/mockName.lua", -- The docs have mockFn commented, causing this test to fail.
      "tests/generated/GlobalAPI/test/failing.lua", -- This test succeeds, but it's supposed to fail
      "tests/generated/GlobalAPI/test/failing/each.lua", -- This test succeeds, but it's supposed to fail
    },

    -- Set to true to show every test result, false to keep output compact.
    -- verbose = true,

    -- Slow down the tests by x milliseconds to make it easier to follow the output. (May cause the screen to flicker)
    -- slowDown = 200,
  })
  :registerTests(function()
    -- Setup and register the tests:
    package.path = package.path .. ";./?.lua;./?/init.lua"
    require "tests.generated"
    require "tests"
  end)
  :runTests()