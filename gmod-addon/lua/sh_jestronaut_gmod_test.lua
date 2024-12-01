--[[
  Self-test for the Jestronaut Garry's Mod addon.
--]]

jestronaut
    :configure({
        roots = {
            "addons/jestronaut/lua/tests/",
            "addons/jestronaut/lua/tests/generated/",
        },

        reporter = GmodReporter
    })
    :registerTests(function()
        jestronaut.callWithRequireCompat(function()
            -- require "tests/generated/init" -- TODO: fails atm
            require "tests/init"
        end)
    end)
    :runTests()
