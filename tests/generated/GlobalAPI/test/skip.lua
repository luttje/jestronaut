-- test.skip



local tests = {

    (function()
        -- For example, let's say you had these tests:
        -- -- Only the "it is raining" test will run, since the other test is run with `test.skip`.
        test(
            "it is raining",
            function()
                expect(inchesOfRain()):toBeGreaterThan(0)
            end
        )
        test:skip(
            "it is not snowing",
            function()
                expect(inchesOfSnow()):toBe(0)
            end
        )
    end)(),


}

return tests
