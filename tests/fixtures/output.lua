-- Tests and hooks that print, used to check that printed output is captured per test.
beforeEach(function()
    print("from beforeEach")
end)

it("prints", function()
    print("hello", 42, nil)
end)

it("prints and fails", function()
    print("before failing")
    error("fails")
end)

it("prints nothing", function() end)
