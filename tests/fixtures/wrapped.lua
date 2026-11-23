-- Loaded inside a describe by wrapper.lua.
beforeEach(function() table.insert(WRAPPER_LOG, "wrapped file beforeEach") end)

it("wrapped test", function() table.insert(WRAPPER_LOG, "wrapped test") end)

describe("wrapped describe", function()
    describe("deeper", function()
        it("deeply wrapped test", function() table.insert(WRAPPER_LOG, "deeply wrapped test") end)
    end)
end)
