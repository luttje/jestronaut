-- Tests marked `only`, used to check that only those run within this file.
it("top-level test without only", function()
    error("Should not be run!")
end)

describe("only tests can fail", function()
    it.failing:skip("skips failing test", function()
        expect("it")["NOTVALIDMODIFIER"]:toBeDefined()
    end)

    it.failing:only("fails on incorrect modifier only to run", function()
        expect("it")["NOTVALIDMODIFIER"]:toBeDefined()
    end)

    it("not run", function()
        error("Should not be run!")
    end)
end)

describe:only("describe marked only", function()
    it("runs because its describe is marked only", function() end)
end)
