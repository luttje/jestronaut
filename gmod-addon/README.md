# Jestronaut - Garry's Mod Addon

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

    ```
    lua_openscript run-all-tests.lua
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