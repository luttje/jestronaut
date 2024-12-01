-- expect.closeTo



local tests = {

    (function()
        -- For example, this test passes with a precision of 5 digits:
        --
        test(
            "compare float in object properties",
            function()
                expect({ title = "0.1 + 0.2", sum = 0.1 + 0.2 }):toEqual({
                    title = "0.1 + 0.2",
                    sum = expect:closeTo(0.3, 5)
                })
            end
        )
    end)(),


}

return tests
