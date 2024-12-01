-- mockFn.mockReturnValueOnce



local tests = {

    (function()
        test("mockFn.mockReturnValueOnce 0", function()
            -- Shorthand for:
            -- -- Accepts a value that will be returned for one call to the mock function. Can be chained so that successive calls to the mock function return different values. When there are no more `mockReturnValueOnce` values to use, calls will return a value specified by `mockReturnValue`.
            jestronaut:fn():mockImplementationOnce(function() return value end)
        end);
    end)(),


    (function()
        test("mockFn.mockReturnValueOnce 1", function()
            local mockFn = jestronaut:fn():mockReturnValue("default"):mockReturnValueOnce("first call")
            :mockReturnValueOnce("second call")
            mockFn()
            mockFn()
            mockFn()
            mockFn()
        end);
    end)(),


}

return tests
