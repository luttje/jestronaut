package.path = package.path .. ";./src/?.lua"

-- require "tests"
require "generated-tests"

local runTests = require "jestronaut.environment.state".runTests
local Printer = require "jestronaut.printer".Printer
runTests(Printer, {
  testPathIgnorePatterns = {
    "^adding works sanely with decimals$", -- This test fails because of floating point errors (the example in Jest docs is meant to fail)
    "^has lemon in it$", -- This test fails because of async not being supported
  }
})