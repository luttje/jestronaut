-- Installs fake timers without removing them, used to check that they are removed after the last test of this file.
it("installs fake timers", function()
    jestronaut:useFakeTimers()
end)
