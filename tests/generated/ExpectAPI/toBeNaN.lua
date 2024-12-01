-- .toBeNaN



local tests = {

    (function()
        test(
            "passes when value is NaN",
            function()
                expect(0 / 0):toBeNaN()
                expect(1)["not"]:toBeNaN()
            end
        )
    end)(),


}

return tests
