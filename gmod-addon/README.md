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
    -- lua/run-all-tests.lua

    include("gmod-jestronaut.lua"):withGlobals()

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

3. Run the runner script in Garry's Mod:

    ```bash
    lua_openscript run-all-tests.lua
    ```

    *The output should look like this:*

    ```
    Running script run-all-tests.lua...
    🚀 Starting 2 tests at 17:26:02...

    STARTED:    o root

    STARTED:      o print

    STARTED:        o should print 'Hello, World!'

    FINISHED:       ✓ should print 'Hello, World!'

    FINISHED:     ✓ print

    FINISHED:   ✓ root


                        🎉 All tests passed. Great job!                     

    Tests:       2 passed, 2 total
    Time:        0.0019999999999527s

    Ran all test suites.
    ```

    *Note that the emoji icons are displayed as `□□` in the Garry's Mod console due to insufficient Unicode support.*

## Testing if Jestronaut is working

Jestronaut's own tests are included in the addon. To run them in Garry's Mod use the following command:

```bash
lua_openscript gmod-test.lua
```
