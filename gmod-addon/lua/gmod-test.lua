--[[
  Self-test for the Jestronaut Garry's Mod addon.
--]]

include("gmod-jestronaut.lua"):withGlobals()

jestronaut
  :configure({
    roots = {
      "addons/jestronaut/lua/tests/",
      "addons/jestronaut/lua/tests/generated/",
    },

    reporter = GmodReporter
  })
  :registerTests(function()
    callWithRequireCompat(function()
      -- require "tests/generated/init" -- TODO: fails atm
      require "tests/init"
    end)
  end)
  :runTests()