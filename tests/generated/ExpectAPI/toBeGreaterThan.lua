-- .toBeGreaterThan



local tests = {

    (function()
        -- Use `toBeGreaterThan` to compare `received > expected` for number or big integer values. For example, test that `ouncesPerCan()` returns a value of more than 10 ounces:
        --
        test(
            "ounces per can is more than 10",
            function()
                expect(ouncesPerCan()):toBeGreaterThan(10)
            end
        )
    end)(),


}

return tests
