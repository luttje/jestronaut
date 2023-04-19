package.path = package.path .. ";./src/?.lua"

-- require "tests"
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
  }
})