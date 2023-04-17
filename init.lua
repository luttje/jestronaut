package.path = package.path .. ";./src/?.lua"

-- require "tests"
require "generated-tests"

local runTests = require "jestronaut.environment.state".runTests
local Printer = require "jestronaut.printer".Printer
runTests(Printer, true)