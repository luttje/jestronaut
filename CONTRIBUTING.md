# 🦾 Contributing

> **Note**
> Before continuing, make sure you have installed:
> * [NodeJS](https://nodejs.org/en/).
> * [LuaRocks](https://luarocks.org/) with at least [Lua 5.1](https://www.lua.org/).
> * [Luvit](https://luvit.io/)

## Building

To build Jestronaut, run the following command:
```bash
npm run build
```

This builds the [LuaRocks](https://luarocks.org/) module and [lit](https://luvit.io/) binary. The binary is written to `dist/jestronaut` and works like the `jestronaut` command of the LuaRocks module.

`npm run build:gmod` builds the Garry's Mod addon into `dist/gmod-addon.zip`.

## Jestronaut's own Tests

Run Jestronaut's tests with any Lua interpreter (5.1 through 5.4 and LuaJIT are supported) from the root of this repository:

```bash
lua test.lua
```

Behaviour of the test runner itself (run results, `bail`, hooks, asynchronous tests, finding test files, ...) can't be checked from inside a single test run. Those checks live in `tests/integration.lua`, which does complete runs over the fixture files in `tests/fixtures/`:

```bash
lua tests/integration.lua
```

The checks for finding test files need [LuaFileSystem](https://lunarmodules.github.io/luafilesystem/) (`luarocks install luafilesystem`), and are skipped without it.

Some fixtures are separate runs that CI checks the exit code of: `tests/fixtures/failing-run.lua` must exit with status code 1, `tests/fixtures/no-globals-run.lua` with 0.

Most tests in `tests/generated` are generated from the Jest documentation. Run `npm run generate-tests` to generate them again, which overwrites everything in `tests/generated`. Examples from the documentation that don't apply to Lua are listed in `testPathIgnorePatterns` in `test.lua` and in the `test` script in `package.json`, with the reason.

For coverage install the following LuaRocks modules:
* `luarocks install luacov`
* `luarocks install luacov-reporter-lcov`

## Type definitions

When changing the API, update `types/jestronaut.lua`. Check it with [Lua Language Server](https://luals.github.io/), for example by running `lua-language-server --check=<folder>` on a folder with a test file and a `.luarc.json` that adds `types` to `workspace.library`.

## Publishing

To publish a new version, for example `0.6-1`:

1. Set the version in `libs/jestronaut.lua` (`0.6-1`) and `package.lua` (`0.6.1`), and move the changes in `CHANGELOG.md` under the new version.

2. Generate the rockspec for the version:

    ```bash
    npm run generate-rockspec -- 0.6-1
    ```

    This writes `rockspecs/jestronaut-0.6-1.rockspec`, which installs the code of the `v0.6-1` tag.

3. Commit the changes, and tag the commit with the version:

    ```bash
    git add .
    git commit -m "Release 0.6-1"
    git tag v0.6-1
    ```

4. Push the commit and tag to GitHub:

    ```bash
    git push origin main --tags
    ```

5. A GitHub Action uploads the new rockspec to LuaRocks, and creates a GitHub release with the lit binaries and the Garry's Mod addon.
