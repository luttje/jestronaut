-- .toHaveBeenCalled



local tests = {

    (function()
        -- For example, let's say you have a `drinkAll(drink, flavour)` function that takes a `drink` function and applies it to all available beverages. You might want to check that `drink` gets called for `'lemon'`, but not for `'octopus'`, because `'octopus'` flavour is really weird and why would anything be octopus-flavoured? You can do that with this test suite:
        --
        local function drinkAll(callback, flavour)
            if flavour ~= "octopus" then
                callback(flavour)
            end
        end
        describe(
            "drinkAll",
            function()
                test(
                    "drinks something lemon-flavoured",
                    function()
                        local drink = jestronaut:fn()
                        drinkAll(drink, "lemon")
                        expect(drink):toHaveBeenCalled()
                    end
                )
                test(
                    "does not drink something octopus-flavoured",
                    function()
                        local drink = jestronaut:fn()
                        drinkAll(drink, "octopus")
                        expect(drink)["not"]:toHaveBeenCalled()
                    end
                )
            end
        )
    end)(),


}

return tests
