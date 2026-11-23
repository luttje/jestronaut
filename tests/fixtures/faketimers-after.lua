-- Runs after faketimers-leak.lua, used to check that its fake timers were removed.
it("runs with real timers", function()
    FAKE_TIMERS_LEAKED = rawget(_G, "setTimeout") ~= nil
end)
