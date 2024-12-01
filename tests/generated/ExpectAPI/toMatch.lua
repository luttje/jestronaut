-- .toMatch



local tests = {

    (function()
        -- For example, you might not know what exactly `essayOnTheBestFlavor()` returns, but you know it's a really long string, and the substring `grapefruit` should be in there somewhere. You can test this with:
        --
        local ____lualib = require("lualib_bundle")
        local __TS__New = ____lualib.__TS__New
        describe(
            "an essay on the best flavor",
            function()
                test(
                    "mentions grapefruit",
                    function()
                        expect(essayOnTheBestFlavor()):toMatch("grapefruit")
                    end
                )
            end
        )
    end)(),


    (function()
        -- This matcher also accepts a string, which it will try to match:
        --
        describe(
            "grapefruits are healthy",
            function()
                test(
                    "grapefruits are a fruit",
                    function()
                        expect("grapefruits"):toMatch("fruit")
                    end
                )
            end
        )
    end)(),


}

return tests
