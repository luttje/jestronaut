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

This builds the [LuaRocks](https://luarocks.org/) module and [lit](https://luvit.io/) binary.

*This will generate a `jestronaut` binary in the `dist` directory of this project. It expects to be added to path and will currently only run tests if you execute jestronaut in the root of your project*

## Jestronaut's own Tests

Most of Jestronaut's own tests are generated from the Jest documentation automatically. 

You can run the test generation script with `npm run generate-tests`. All tests in `tests/generated` will be overwritten.

Use `luarocks test` in the root of this repo to execute the Jestronaut tests.

For coverage install the following LuaRocks modules:
* `luarocks install luacov`
* `luarocks install luacov-reporter-lcov`

## Publishing

To publish Jestronaut to LuaRocks:

1. Build Jestronaut

    ```bash
    npm run build
    ```

    This will generate a `jestronaut-scm-0.rockspec` file in the root of this project.
    
2. Copy `jestronaut-scm-0.rockspec` to `rockspecs/jestronaut-<version>.rockspec` and update the version number to the new version:

    *For example for version `v0.5-2`*

    ```bash
    cp jestronaut-scm-0.rockspec rockspecs/jestronaut-0.5-2.rockspec
    ```

3. Modify the contents of the `rockspecs/jestronaut-<version>.rockspec` file to match the new version:

    ```lua
    package = "jestronaut"
    version = "0.5-2"
    -- the rest of the rockspec file remains unchanged
    ```

4. Commit theses changes to the repository:

    ```bash
    git add .
    git commit -m "Update rockspec for version 0.5-2"
    ```

5. Tag the commit with the new version:

    ```bash
    git tag v0.5-2
    ```

6. Push the commit and tag to GitHub:

    ```bash
    git push origin main --tags
    ```

7. A GitHub Action will automatically build and publish the new version to LuaRocks.
