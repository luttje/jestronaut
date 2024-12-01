-- expect



local tests = {

    (function()
        -- It's easier to understand this with an example. Let's say you have a method `bestLaCroixFlavor()` which is supposed to return the string `'grapefruit'`. Here's how you would test that:
        -- -- In this case, `toBe` is the matcher function. There are a lot of different matcher functions, documented below, to help you test different things.
        test(
            "the best flavor is grapefruit",
            function()
                expect(bestLaCroixFlavor()):toBe("grapefruit")
            end
        )
    end)(),


}

return tests
