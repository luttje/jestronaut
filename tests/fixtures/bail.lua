-- Three failing tests and one passing test, used to check the bail option.
it("fails first", function()
    expect(1):toBe(2)
end)

it("fails second", function()
    expect(1):toBe(2)
end)

it("passes", function()
    expect(1):toBe(1)
end)

it("fails third", function()
    expect(1):toBe(2)
end)
