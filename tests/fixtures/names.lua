-- Nested describes, used to check the testNamePattern option.
it("top-level test", function()
    expect(true):toBe(true)
end)

describe("outer", function()
    it("outer test", function()
        expect(true):toBe(true)
    end)

    describe("inner", function()
        it("first inner test", function()
            expect(true):toBe(true)
        end)

        it("second inner test", function()
            expect(true):toBe(true)
        end)
    end)
end)
