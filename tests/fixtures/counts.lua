-- Tests nested at several levels, with skipped, todo and failing tests, used to check the counts.
it("level 1 test", function() end)

describe("level 1", function()
    it("level 2 test", function() end)

    describe("level 2", function()
        it("level 3 test", function() end)

        describe("level 3", function()
            it("level 4 test", function() end)
            it("level 4 failing test", function() error("fails") end)
            it:skip("level 4 skipped test", function() end)
            it:todo("level 4 todo test")
        end)
    end)
end)

describe:skip("skipped describe", function()
    it("skipped because of its describe", function() end)
end)
