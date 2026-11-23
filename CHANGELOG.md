# Changelog

## 0.6-1 (unreleased)

This release makes Jestronaut behave like Jest in many places where it didn't before. Some of those changes can make
tests that used to pass fail, see the breaking changes below.

### Breaking changes

- Runs exit with status code 1 when a test fails. Set `exitOnFailure = false` to keep the process running.
- `bail` defaults to `0`, so all tests run instead of stopping at the first failure.
- `only` works per test file, like in Jest: once a file has tests or describes marked `only`, its other tests are
  skipped.
- `beforeAll` and `afterAll` run once per file or describe, instead of around every test. All hooks belong to the
  describe they are declared in, and there can be several of each.
- `retryTimes` gives every test its own retries, instead of sharing them across the file.
- `toEqual` compares tables in both directions, so extra keys in the received table fail. `not` works on partially
  equal tables.
- `toContain` and `toContainEqual` fail when the item is missing. They never failed before.
- `toBe` checks identity: it no longer uses `__eq` metamethods or custom equality testers. Use `toEqual` for those.
- `toBeCloseTo` uses Jest's tolerance (a difference of less than `10^-digits / 2`), which is stricter.
- `toThrow` respects `not`, and matches messages literally before trying them as a Lua pattern.
- `mock.results` entries are `{ type = "return", value = ... }` tables, like in Jest.
- Matchers added with `expect.extend` receive the received value and the matcher's arguments, and return
  `{ pass, message }`, like in Jest.
- Matcher names are case-sensitive on every platform. On Windows `expect(x):tobe(y)` used to work.
- A run that finds no tests fails, unless `passWithNoTests` is set.
- Registering tests or hooks inside a running test raises an error.
- The test counts only count tests, not describes.
- LuaFileSystem is a new dependency.

### Added

- A `jestronaut` command that finds test files (`*_test.lua`, `*_spec.lua`, `*.test.lua`, `*.spec.lua`) and runs
  them, with the options as `--name=value` arguments. `registerTests()` without arguments finds test files too, and it
  also accepts a list of test files.
- Asynchronous tests and hooks with a `done` callback, `jestronaut:async` for Lua 5.1, the `testTimeout` option and
  the `eventLoop` option to wait with your own event loop or from an application's loop (`jestronaut:tick()`).
- Fake timers: `jestronaut:useFakeTimers()`, `advanceTimersByTime`, `runAllTimers` and the other Jest timer functions.
- `describe`, `it`, `expect` and the hooks on the module, to write tests without globals.
- Type definitions for Lua Language Server in `types/jestronaut.lua`.
- Readable failure messages in Jest's format, with the path to the first difference for tables, and tracebacks without
  Jestronaut's own frames.
- What tests print is captured and shown after the run. The `silent` option hides it.
- A plain reporter for CI and terminals without colors, used when `CI` or `NO_COLOR` is set (the `ci` and `colors`
  options).
- `testMatch`, `testPathPattern` and `passWithNoTests` options.
- `jestronaut:setTimeout` sets the default timeout of tests and hooks.
- Run results with counts are passed to the `runTests` callback.
- Support for Lua 5.2, 5.3 and 5.4.

### Fixed

- Test counts were wrong when describes were nested (#10).
- Most matchers ignored `not` in their message, and several ignored it when deciding (#6).
- `testNamePattern` skipped everything when `testPathIgnorePatterns` was set, and skipped tests in describes whose
  name didn't match.
- `bail` stopped at the first failure whatever its value, and `bail = false` crashed.
- Errors in hooks crashed the run instead of failing the tests.
- `toHaveProperty` treated properties set to `false` as missing.
- `toMatch` crashed when the string didn't match.
- `toStrictEqual` only compared metatables at the top level.
- `toEqual` passed when a custom equality tester returned `false`, never matched `NaN`, and overflowed the stack on
  cyclic tables.
- `toBeCloseTo` and `expect:closeTo` failed on Lua 5.4, which has no `math.pow`.
- `mockRestore` and `restoreAllMocks` didn't restore spies. Calling a mock after `mockReset` crashed.
- Property spies returned the spied value for other missing keys, and "get" spies dropped assignments to other keys.
- Mocks that returned nothing didn't count as having returned.
- `test.concurrent` tests were dropped instead of run.
- The reporter crashed on errors that aren't strings, and showed files with failures as passed.
- In Garry's Mod, prints were swallowed while tests waited for `done`, and the reporter crashed when a describe
  failed.

## 0.5-1 and earlier

See the [GitHub releases](https://github.com/luttje/jestronaut/releases).
