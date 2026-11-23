-- The tests of counts.lua wrapped in a describe. Wrapping must not change the counts (see issue #10).
describe("all tests", function()
    dofile("./tests/fixtures/counts.lua")
end)
