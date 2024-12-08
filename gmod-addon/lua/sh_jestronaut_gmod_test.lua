--[[
  Self-test for the Jestronaut Garry's Mod addon.
--]]

jestronaut
    :configure({
        roots = {
            "addons/jestronaut/lua/",
            "addons/jestronaut/lua/tests/",
            "addons/jestronaut/lua/tests/generated/",
        },

        -- Sets up the event loop ticker for Garry's Mod
        eventLoopTicker = function(ticker)
            hook.Add("Think", "AsyncTestRunner", function()
                if ticker() == false then
                   hook.Remove("Think", "AsyncTestRunner")
                end
            end)
        end,

        reporter = GmodReporter
    })
    :registerTests(function()
        jestronaut.callWithRequireCompat(function()
            -- require "tests/generated/init" -- TODO: fails atm
            include("sh_jestronaut_test_mysqloo.lua")
            require "tests/init"
        end)
    end)
    :runTests()
