-- .toBeCloseTo



local tests = {

    (function()
        -- Intuitive equality comparisons often fail, because arithmetic on decimal (base 10) values often have rounding errors in limited precision binary (base 2) representation. For example, this test fails:
        -- -- It fails because in JavaScript, `0.2 + 0.1` is actually `0.30000000000000004`.
        test(
            "adding works sanely with decimals",
            function()
                expect(0.2 + 0.1):toBe(0.3)
            end
        )
    end)(),


    (function()
        -- For example, this test passes with a precision of 5 digits:
        -- -- Because floating point errors are the problem that `toBeCloseTo` solves, it does not support big integer values.
        test(
            "adding works sanely with decimals",
            function()
                expect(0.2 + 0.1):toBeCloseTo(0.3, 5)
            end
        )
    end)(),


}

return tests
