package.path = package.path .. ";./src/?.lua"
require "jestronaut":withGlobals()

-- Required so Jestronaut can figure out what may be test files (TODO: Should be more stable and less easy to forget):
jestronaut:setTestRoot("./src/tests/")

-- Setup and start the tests:
-- require "tests"

-- Required so Jestronaut can figure out what may be test files (TODO: Should be more stable and less easy to forget):
jestronaut:setTestRoot("./src/generated-tests/")

-- Setup and start the tests:
require "generated-tests"

local runTests = require "jestronaut.environment.state".runTests
local Printer = require "jestronaut.printer".Printer
runTests(Printer, {
  testPathIgnorePatterns = {
    "/generated%-tests/ExpectAPI/toBeCloseTo.lua$/", -- This test fails because of floating point errors (the example in Jest docs is meant to fail)
    "/generated%-tests/GlobalAPI/test.lua$/", -- This test fails because of async not being supported

    -- Fake timer functions not supported yet:
    "generated-tests/JestObjectAPI/jest/useFakeTimers.lua",
    "generated-tests/JestObjectAPI/jest/useRealTimers.lua",

    "generated-tests/JestObjectAPI/jest/retryTimes.lua", -- These tests are intended to fail

    "generated-tests/MockFunctionAPI/mockFn/mockName.lua", -- The docs have mockFn commented, causing this test to fail.
  }
})