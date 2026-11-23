-- Failing tests, used to check that stack tracebacks only show frames outside Jestronaut.
local function assertTwo(value)
    expect(value):toBe(2)
end

it("fails directly", function()
    expect(1):toBe(2)
end)

it("fails in a helper", function()
    assertTwo(1)
end)
