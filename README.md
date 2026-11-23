> [!WARNING]
> Jestronaut is still in early development.

<div align="center">

<img src="./docs/logo-without-background.png" alt="Jestronaut logo showing a jester in a space helmet" width="200" />

# Jestronaut 

[![License](https://img.shields.io/github/license/luttje/jestronaut)](https://github.com/luttje/jestronaut/blob/main/LICENSE)
[![LuaRocks](https://img.shields.io/luarocks/v/luttje/jestronaut)](https://luarocks.org/modules/luttje/jestronaut)
[![GitHub Tests Action](https://github.com/luttje/jestronaut/actions/workflows/tests.yml/badge.svg)](https://github.com/luttje/jestronaut/actions/workflows/tests.yml)
[![Dependency status](https://img.shields.io/librariesio/github/luttje/jestronaut)](https://libraries.io/github/luttje/jestronaut)
[![Test Coverage Status](https://coveralls.io/repos/github/luttje/jestronaut/badge.svg?branch=main)](https://coveralls.io/github/luttje/jestronaut?branch=main)

</div>

A Lua library for testing your code. It does for Lua what [Jest](https://jestjs.io/) does for JavaScript, with a similar API. 

Jestronaut allows you to assert, mock, and spy on your code with ease. It includes a test-runner that you can start from the CLI or Lua:

![Jestronaut output showing green signals besides all tests in 4 files to indicate the tests inside passed](./docs/output.gif)

*For this GIF the tests were run with the verbose and 200ms slowDown settings. Some frames were cut to prevent flickering. The actual duration of these tests was around 0.043s*

## 🚀 Getting Started

First create a test file inside your project, for example:
```lua
-- tests/my_test.lua
describe("my test", function()
  it("should pass", function()
    expect(1 + 1):toBe(2)
  end)
end)
```

Then you can choose one of several ways to run the tests with Jestronaut:

* [Run tests with LuaRocks](#run-in-project-with-luarocks)
* [Download the standalone binary and run tests anywhere](#running-tests-with-lit-binary).
* [Run tests in Garry's Mod](./gmod-addon/README.md)

### Run in project with LuaRocks

> [!NOTE]
> Before continuing, make sure you have installed [LuaRocks](https://luarocks.org/) with at least [Lua 5.1](https://www.lua.org/).

1. Install Jestronaut as a LuaRocks module in your project
    ```bash
    luarocks install jestronaut
    ```

2. Create a test runner file in the root of your project named `test.lua`:
    ```lua
    require "jestronaut":withGlobals()

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

3. In the root of your project, start your tests by using the Lua CLI: 

    For example:

    ```bash
    lua test.lua
    ```

    Or if your Lua installation has a different name:

    ```bash
    lua5.1.exe test.lua
    ```

    When any test fails, Jestronaut exits with status code `1`, so CI pipelines fail as expected. When the `CI` environment variable is set (as most CI services do), or colors are turned off with `NO_COLOR`, Jestronaut prints a plain log instead of redrawing its output. Set the `ci` and `colors` options to choose yourself. If you embed Jestronaut in a host application that should keep running, set `exitOnFailure = false` and inspect the results passed to `runTests` instead:

    ```lua
    jestronaut
      :configure({ roots = { "./tests/" }, exitOnFailure = false })
      :registerTests(function() --[[ ... ]] end)
      :runTests(function(results)
        print(results.success, results.failedCount, results.skippedCount)
      end)
    ```

### Running tests with lit binary

This binary is a standalone executable that can be used to run Jestronaut tests anywhere.

1. Download the latest binary from the [releases page](https://github.com/luttje/jestronaut/releases).

2. Install the binary somewhere in your PATH and make sure it's named `jestronaut` (or `jestronaut.exe` on Windows)

3. Run the tests with `jestronaut`, for example:

    ```bash
    MSYS_NO_PATHCONV=1 jestronaut \
      --roots=./tests/generated \
      --roots=./tests \
      --testPathIgnorePatterns="/tests/generated/ExpectAPI/toBeCloseTo.lua$/" \
      --testPathIgnorePatterns="/tests/generated/GlobalAPI/test.lua$/"
    ```

> [!NOTE]
> The variable `MSYS_NO_PATHCONV=1` in the example above is only required on Windows when using MSYS2 (for example with Git for Windows). It prevents the path from being converted to a Windows path, which would result in an incorrect path.

### Running tests in Garry's Mod

See [the Jestronaut Garry's Mod addon README](./gmod-addon/README.md) for more information.

## 🧪 API

Jestronaut tries to match [the API of Jest](https://jestjs.io/docs/api) as closely as possible. Here are some examples of how to use it:

```lua
describe("test organization into suites", function()
  it("should confirm basic math", function()
    expect(1 + 1):toBe(2)      
  end)
end)

it("should let sums NOT match", function()
  expect(1 + 1)['not']:toBe(3)
  expect(1 + 5)['not']:toBeGreaterThan(7)
end)

it("should have all the matchers Jest has", function()
  expect(1 + 1):toBe(2)
  expect(0.1 + 5.2):toBeCloseTo(5.3)
  expect({}):toBeDefined()
  expect(nil):toBeFalsy()
  expect(1 + 1):toBeGreaterThan(1)
  expect(1 + 1):toBeGreaterThanOrEqual(2)
  expect(1 + 1):toBeLessThan(3)
  expect(1 + 1):toBeLessThanOrEqual(2)
  expect(0/0):toBeNaN()
  expect(nil):toBeNil()
  expect(nil):toBeNull()
  expect(1 + 1):toBeTruthy()
  expect(1 + 1):toBeType('number')
  expect(nil):toBeUndefined()
  expect({1, 2, 3}):toContain(2)
  expect({1, 2, 3}):toContainEqual(2)
  expect({1, 2, 3}):toEqual({1, 2, 3})
  expect({1, 2, 3}):toHaveLength(3)
  expect({
    a = 1,
    b = 2,
    c = 3
  }):toHaveProperty('a')
  expect("abc"):toMatch("c$") -- Lua patterns
  expect({
    a = 1,
    b = 2,
    c = 3
  }):toMatchObject({
    a = 1,
    b = 2
  })
  expect({}):toStrictEqual({})
  expect(function() error('test') end):toThrow('test')
  expect(function() error('testing') end):toThrowError('testing')
end)

it('should be able to mock function implementations', function()
  local mockFn = jestronaut:fn(function() return 'x', 'y', 'z' end)
  mockFn(1, 2, 3)

  expect(mockFn):toHaveBeenCalled()
  expect(mockFn):toHaveBeenCalledTimes(1)
  expect(mockFn):toHaveBeenCalledWith(1, 2, 3)
  
  mockFn(3, 2, 1)
  expect(mockFn):toHaveBeenLastCalledWith(3, 2, 1)
  expect(mockFn):toHaveBeenNthCalledWith(1, 1, 2, 3)
  expect(mockFn):toHaveLastReturnedWith('x', 'y', 'z')
  expect(mockFn):toHaveNthReturnedWith(1, 'x', 'y', 'z')
  expect(mockFn):toHaveReturned()
  expect(mockFn):toHaveReturnedTimes(2)
  expect(mockFn):toHaveReturnedWith('x', 'y', 'z')
end)

local ranBefore = 0
beforeAll(function()
  ranBefore = ranBefore + 1
end)

it('runs beforeAll once, before the first test in its scope', function()
  expect(ranBefore):toEqual(1)
end)

it('can spy on a property setter', function()
  local audio = {
    volume = 0,
  }
  local spy = jestronaut:spyOn(audio, 'volume', 'set')
  audio.volume = 100

  expect(spy):toHaveBeenCalled()
  expect(audio.volume):toBe(100)
end)

it('can spy on a property getter', function()
  local audio = {
    volume = 0,
  }
  local spy = jestronaut:spyOn(audio, 'volume', 'get')
  print(audio.volume)

  expect(spy):toHaveBeenCalled()
  expect(audio.volume):toBe(0)
end)

it:failing('should be able to expected failures', function()
  expect(1 + 1):toEqual(1)
end)

it:skip('should be able to skip tests', function()
  expect(1 + 1):toEqual(1)
end)

it:each({{1, 1, 2}, {1, 2, 3}, {2, 1, 3}})(
  "can loop data (%i, %i = %i)",
  function(a, b, expected)
    expect(a + b):toBe(expected)
  end
)
```

Check out [the Jestronaut tests](https://github.com/luttje/jestronaut/tree/main/tests) for more examples.

### Testing asynchronous code

Like [in Jest](https://jestjs.io/docs/asynchronous#callbacks), a test (or hook) that takes a `done` parameter only finishes once it calls `done`. Pass an error to `done` to fail the test:

```lua
it("fetches the data", function(done)
  fetchData(function(err, data)
    if err then
      done(err)
      return
    end

    expect(data):toBe("peanut butter")
    done()
  end)
end, 1000) -- Optional timeout in milliseconds, defaults to the testTimeout option (5000)
```

On Lua 5.1 Jestronaut can't see whether a function takes a parameter, so wrap asynchronous functions with `jestronaut:async`. This works on every Lua version:

```lua
it("fetches the data", jestronaut:async(function(done)
  -- ...
end))
```

To wait for `done`, Jestronaut needs to know how your code runs its callbacks. Set the `eventLoop` option to one of:

* `tick`: a function Jestronaut calls repeatedly while it waits. Errors raised in it, like a failing `expect` in a callback, fail the test. For example with [luv](https://github.com/luvit/luv):

    ```lua
    local uv = require "luv"

    jestronaut:configure({
      roots = { "./tests/" },
      eventLoop = {
        tick = function() uv.run("once") end,
        now = function() return uv.now() / 1000 end, -- Current time in seconds, used for timeouts
      },
    })
    ```

* `external = true`: for applications that run their own loop, like games. `runTests` returns right away and the tests continue each time you call `jestronaut:tick()`, which returns `true` once they are done. Errors raised in callbacks are handled by your application, so pass them to `done` yourself. For example in Garry's Mod:

    ```lua
    jestronaut
      :configure({
        roots = { "addons/my_addon/lua/tests/" },
        eventLoop = { external = true, now = SysTime },
      })
      :registerTests(function() --[[ ... ]] end)
      :runTests(function(results)
        print("Tests finished, " .. results.failedCount .. " failed")
      end)

    hook.Add("Think", "RunJestronautTests", function()
      if jestronaut:tick() then
        hook.Remove("Think", "RunJestronautTests")
      end
    end)
    ```

Without an `eventLoop`, tests can still call `done` before they return. `test.concurrent` tests are supported, but run one after another.

## 🦾 Contributing

Contributions are welcome! Check out [`CONTRIBUTING.md`](./CONTRIBUTING.md) for more information.
