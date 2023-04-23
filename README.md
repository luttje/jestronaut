# Jestronaut

> **Warning**
> Jestronaut is still in early development.

A Lua library for testing your code. It tries to work similarly to [Jest](https://jestjs.io/).

![Jestronaut output showing green signals besides 3 files to indicate the tests inside passed](./docs/output.png)

## 🚀 Getting Started

> **Note**
> Before continuing, make sure you have installed [Luarocks](https://luarocks.org/) with at least [Lua 5.1](https://www.lua.org/).

1. Install Jestronaut as a LuaRocks module in your project
    ```bash
    luarocks install jestronaut
    ```

2. Create a test file inside your project, for example:
    ```lua
    -- tests/my_test.lua

    require "jestronaut":withGlobals()

    describe("my test", function()
      it("should pass", function()
        expect(1 + 1):toBe(2)
      end)
    end)
    ```

Then you can choose one of two ways to run the tests with Jestronaut:
1. [Run in project with LuaRocks](#run-in-project-with-luarocks)
2. [Download the binary and run tests anywhere](#running-tests-with-lit-binary)

### Run in project with LuaRocks

1. Create a test runner file in the root of your project named `test.lua`:
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

4. In the root of your project, start your tests using LuaRocks: `luarocks test` or with plain Lua: `lua test.lua`.

### Running tests with lit binary

This binary is a standalone executable that can be used to run Jestronaut tests anywhere. It is built with [lit](https://luvit.io/).

1. Download the latest binary from the [releases page](https://github.com/luttje/jestronaut/releases)

2. Install the binary somewhere in your PATH

3. Run the tests with `jestronaut`, for example:

    ```bash
    jestronaut \
      --roots=./tests/generated \
      --roots=./tests \
      --testPathIgnorePatterns=\"/tests/generated/ExpectAPI/toBeCloseTo.lua$/\" \
      --testPathIgnorePatterns=\"/tests/generated/GlobalAPI/test.lua$/\"
    ```


## 🧪 Contributing

> **Note**
> Before continuing, make sure you have installed:
> * [NodeJS](https://nodejs.org/en/).
> * [Luarocks](https://luarocks.org/) with at least [Lua 5.1](https://www.lua.org/).

### Building

The LuaRocks module is built using:

```bash
luarocks make --local
```

The Lit binary is built using:
  
  ```bash
  npm run build
  ```

*This will generate a `jestronaut.exe` binary in the `dist` directory of this project. It expects to be added to path and will currently only run tests if you execute jestronaut in the root of your project*

### Jestronaut's own Tests

Most of Jestronaut's own tests are generated from the Jest documentation automatically. 

You can run the test generation script with `npm run generate-tests`. All tests in `tests/generated` will be overwritten.

Use `luarocks test` in the root of this repo to execute the Jestronaut tests.