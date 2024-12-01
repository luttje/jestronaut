-- mockFn.mockImplementationOnce



local tests = {

    (function()
        test("mockFn.mockImplementationOnce 0", function()
            local mockFn = jestronaut:fn():mockImplementationOnce(function(cb) return cb(nil, true) end)
            :mockImplementationOnce(function(cb) return cb(nil, false) end)
            mockFn(function(err, val) return print(val) end)
            mockFn(function(err, val) return print(val) end)
        end);
    end)(),


    (function()
        test("mockFn.mockImplementationOnce 1", function()
            -- When the mocked function runs out of implementations defined with `.mockImplementationOnce()`, it will execute the default implementation set with `jest.fn(() => defaultValue)` or `.mockImplementation(() => defaultValue)` if they were called:
            --
            local mockFn = jestronaut:fn(function() return "default" end):mockImplementationOnce(function() return
                "first call" end):mockImplementationOnce(function() return "second call" end)
            mockFn()
            mockFn()
            mockFn()
            mockFn()
        end);
    end)(),


}

return tests
