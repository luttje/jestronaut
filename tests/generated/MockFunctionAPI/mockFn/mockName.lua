-- mockFn.mockName



local tests = {

    (function()
        test("mockFn.mockName 0", function()
            -- For example:
            --
            local mockFn = jestronaut:fn():mockName("mockedFunction")
            expect(mockFn):toHaveBeenCalled()
        end);
    end)(),


}

return tests
