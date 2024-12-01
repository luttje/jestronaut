-- jest.useFakeTimers



local tests = {

    (function()
        -- You can call `jest.useFakeTimers()` or `jest.useRealTimers()` from anywhere: top level, inside an `test` block, etc. Keep in mind that this is a **global operation** and will affect other tests within the same file. Calling `jest.useFakeTimers()` once again in the same test file would reset the internal state (e.g. timer count) and reinstall fake timers using the provided options:
        -- -- :::info Legacy Fake Timers
        --
        -- For some reason you might have to use legacy implementation of fake timers. It can be enabled like this (additional options are not supported):
        --
        -- ```js
        -- jest.useFakeTimers({
        --   legacyFakeTimers: true,
        -- });
        -- ```
        --
        -- Legacy fake timers will swap out `setImmediate()`, `clearImmediate()`, `setInterval()`, `clearInterval()`, `setTimeout()`, `clearTimeout()` with Jest [mock functions](MockFunctionAPI.md). In Node environment `process.nextTick()` and in JSDOM environment `requestAnimationFrame()`, `cancelAnimationFrame()` will be also replaced.
        test(
            "advance the timers automatically",
            function()
                jestronaut:useFakeTimers({ advanceTimers = true })
            end
        )
        test(
            "do not advance the timers and do not fake `performance`",
            function()
                jestronaut:useFakeTimers({ doNotFake = { "performance" } })
            end
        )
        test(
            "uninstall fake timers for the rest of tests in the file",
            function()
                jestronaut:useRealTimers()
            end
        )
    end)(),


}

return tests
