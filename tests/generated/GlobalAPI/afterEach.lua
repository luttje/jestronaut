-- afterEach



local tests = {

    (function()
        -- For example:
        -- -- Here the `afterEach` ensures that `cleanUpDatabase` is called after each test runs.
        local globalDatabase = makeGlobalDatabase()
        local function cleanUpDatabase(db)
            db:cleanUp()
        end
        afterEach(function()
            cleanUpDatabase(globalDatabase)
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
