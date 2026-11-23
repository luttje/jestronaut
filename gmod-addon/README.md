<div align="center">

<img src="./logo-with-gmod.png" alt="Jestronaut logo showing a jester in a space helmet" width="200" />

# Jestronaut - Garry's Mod Addon

[![License](https://img.shields.io/github/license/luttje/jestronaut)](https://github.com/luttje/jestronaut/blob/main/LICENSE)
[![GitHub Release](https://img.shields.io/github/v/release/luttje/jestronaut)](https://github.com/luttje/jestronaut/releases)

</div>

This addon provides a way to run [Jestronaut](https://github.com/luttje/jestronaut) tests in Garry's Mod. It includes the Jestronaut library and a reporter for Garry's Mod.

> [!WARNING]
> The addon has quite a hacky implementation surrounding `require`.
> This is done to make `require` return values from modules it requires.
>
> If you find that this causes issues, feel free to open an issue.

## Installation

1. Download the addon from the assets of the latest Jestronaut release from the 
[releases page](https://github.com/luttje/jestronaut/releases). The file is named `gmod-addon.zip`.

2. Extract the contents of the `gmod-addon.zip` file to your Garry's Mod `addons` folder.

3. Restart Garry's Mod if it was running.

## Usage

1. Create some test files in your project, for example:

    ```lua
    -- lua/tests/print_test.lua

    describe("print", function()
      it("should print 'Hello, World!'", function()
        local mockFn = jestronaut:fn()

        expect(mockFn)['not']:toHaveBeenCalled()
        mockFn("Hello, World!")

        expect(mockFn):toHaveBeenCalledWith("Hello, World!")
      end)
    end)
    ```

2. Create a runner script in your project, for example:

    ```lua
    -- lua/run_all_tests.lua

    jestronaut
      :configure({
        roots = {
          -- Where your tests are located, needed for the reporter to find the source files:
          "lua/tests/",
        },

        -- Prints to console:
        reporter = GmodReporter
      })
      :registerTests(function()
        include("tests/print_test.lua")
      end)
      :runTests()
    ```

    Garry's Mod has no LuaFileSystem, so Jestronaut can't find test files itself: load them with `include` in the
    function passed to `registerTests`.

3. Run the runner script in Garry's Mod:

    ```bash
    lua_openscript run_all_tests.lua
    ```

    *The output should look like this:*

    ```
    Running script run_all_tests.lua...
    🚀 Starting 1 tests at 17:26:02...

    STARTED:    o root

    STARTED:      o print

    STARTED:        o should print 'Hello, World!'

    FINISHED:       ✓ should print 'Hello, World!'

    FINISHED:     ✓ print

    FINISHED:   ✓ root


                        🎉 All tests passed. Great job!                     

    Tests:       1 passed, 1 total
    Time:        0.0019999999999527s

    Ran all test suites.
    ```

    *Note that the emoji icons are displayed as `□□` in the Garry's Mod console due to insufficient Unicode support.*

## Asynchronous tests

Tests that take a `done` callback can wait for timers, network requests and the like. Garry's Mod runs its own loop,
so let Jestronaut continue the tests from a `Think` hook, and use `SysTime` as the clock for timeouts:

```lua
jestronaut
  :configure({
    roots = { "lua/tests/" },
    reporter = GmodReporter,
    eventLoop = { external = true, now = SysTime },
  })
  :registerTests(function()
    include("tests/print_test.lua")
  end)
  :runTests(function(results)
    print("Tests finished, " .. results.failedCount .. " failed")
  end)

hook.Add("Think", "RunJestronautTests", function()
  if jestronaut:tick() then
    hook.Remove("Think", "RunJestronautTests")
  end
end)
```

Errors raised in timer or hook callbacks are handled by Garry's Mod, so catch them and pass them to `done` to fail the
test with them. See [Testing asynchronous code](../README.md#testing-asynchronous-code) for more.

Fake timers (`jestronaut:useFakeTimers()`) replace `os.time`, `os.clock` and `os.date`, but not Garry's Mod's own
`CurTime`, `SysTime` or `timer` library.

## Testing if Jestronaut is working

Jestronaut's own tests are included in the addon. To run them in Garry's Mod use the following command:

```bash
lua_openscript sh_jestronaut_gmod_test.lua
```
