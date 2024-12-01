-- expect.anything



local tests = {

    (function()
        -- `expect.anything()` matches anything but `null` or `undefined`. You can use it inside `toEqual` or `toBeCalledWith` instead of a literal value. For example, if you want to check that a mock function is called with a non-null argument:
        --
        local ____lualib = require("lualib_bundle")
        local __TS__ArrayMap = ____lualib.__TS__ArrayMap
        test(
            "map calls its argument with a non-null argument",
            function()
                local mock = jestronaut:fn()
                __TS__ArrayMap(
                    { 1 },
                    function(____, x) return mock(x) end
                )
                expect(mock):toHaveBeenCalledWith(expect:anything())
            end
        )
    end)(),


}

return tests
