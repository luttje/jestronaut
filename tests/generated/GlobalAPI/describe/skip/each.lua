-- describe.skip.each



local tests = {

    (function()
        describe.skip:each({ { 1, 1, 2 }, { 1, 2, 3 }, { 2, 1, 3 } })(
            ".add(%i, %i)",
            function(a, b, expected)
                test(
                    "returns " .. tostring(expected),
                    function()
                        expect(a + b):toBe(expected)
                    end
                )
            end
        )
        test(
            "will be run",
            function()
                expect(1 / 0):toBe(math.huge)
            end
        )
    end)(),


}

return tests
