-- .toEqual



local tests = {

    (function()
        -- For example, `.toEqual` and `.toBe` behave differently in this test suite, so all the tests pass:
        -- -- :::tip
        --
        -- `toEqual` ignores object keys with `undefined` properties, `undefined` array items, array sparseness, or object type mismatch. To take these into account use [`.toStrictEqual`](#tostrictequalvalue) instead.
        local can1 = { flavor = "grapefruit", ounces = 12 }
        local can2 = { flavor = "grapefruit", ounces = 12 }
        describe(
            "the La Croix cans on my desk",
            function()
                test(
                    "have all the same properties",
                    function()
                        expect(can1):toEqual(can2)
                    end
                )
                test(
                    "are not the exact same can",
                    function()
                        expect(can1)["not"]:toBe(can2)
                    end
                )
            end
        )
    end)(),


}

return tests
