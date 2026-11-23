-- Wraps the tests of another file (wrapped.lua) in a describe, like the reproduction in issue #10.
-- Hooks at the top of wrapped.lua must only apply to the tests in wrapped.lua, not to the tests here.
WRAPPER_LOG = {}

describe("wrapper", function()
    beforeEach(function() table.insert(WRAPPER_LOG, "wrapper beforeEach") end)

    it("wrapper test", function() table.insert(WRAPPER_LOG, "wrapper test") end)

    dofile("./tests/fixtures/wrapped.lua")
end)
