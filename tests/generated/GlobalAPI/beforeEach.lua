-- beforeEach



local tests = {

    (function()
        -- For example:
        -- -- Here the `beforeEach` ensures that the database is reset for each test.
        local globalDatabase = makeGlobalDatabase()
        beforeEach(function()
            local ____self_0 = globalDatabase:clear()
            return ____self_0["then"](
                ____self_0,
                function()
                    return globalDatabase:insert({ testData = "foo" })
                end
            )
        end)
        test(
            "can find things",
            function()
                return globalDatabase:find(
                    "thing",
                    {},
                    function(results)
                        expect(results.length):toBeGreaterThan(0)
                    end
                )
            end
        )
        test(
            "can insert a thing",
            function()
                return globalDatabase:insert(
                    "thing",
                    makeThing(),
                    function(response)
                        expect(response.success):toBeTruthy()
                    end
                )
            end
        )
    end)(),


}

return tests
