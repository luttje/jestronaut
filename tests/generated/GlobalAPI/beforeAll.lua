-- beforeAll



local tests = {

    (function()
        -- For example:
        -- -- Here the `beforeAll` ensures that the database is set up before tests run. If setup was synchronous, you could do this without `beforeAll`. The key is that Jest will wait for a promise to resolve, so you can have asynchronous setup as well.
        local globalDatabase = makeGlobalDatabase()
        beforeAll(function()
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
    end)(),


}

return tests
