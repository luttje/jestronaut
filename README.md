# Jestronaut

A Lua library for testing your code. It tries to work similarly to [Jest](https://jestjs.io/).

## 🚀 Getting Started

Before continuing, make sure you have the following installed:

- [Luarocks](https://luarocks.org/) with at least [Lua 5.1](https://www.lua.org/)

### 1. Installation

#### Installing through Luarocks

In your project directory, run:

```bash
luarocks install jestronaut
```

#### 2. Usage

1. Create a test file, for example `tests/my_test.lua`:
    ```lua
    require "jestronaut":withGlobals()

    describe("my test", function()
      it("should pass", function()
        expect(1 + 1):toBe(2)
      end)
    end)
    ```

2. Create a test runner file in the root of your project named `test.lua`:
    ```lua
    local jestronaut = require "jestronaut"

    jestronaut
      :configure({
        roots = {
          "./tests/", -- Directory where you saved the test file above
        },
      })
      :registerTests(function()
        package.path = package.path .. ";./tests/?.lua"
        require "my_test"
      end)
      :runTests()
    ```

3. Using LuaRocks, start your tests with `luarocks test` OR with plain Lua, run `lua test.lua`.

## 🧪 Testing Jestronaut itself

In order to match the Jest API, Jestronaut has a script that will scrape the Jest documentation and generate the tests for Jestronaut. You can run the script with `npm run generate-tests`. All tests in `tests/generated` will be overwritten.

Use `luarocks test` to execute the Jestronaut tests.