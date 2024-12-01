local require = require
local mockFunctionLib = require "jestronaut/mock/mockfunction"

local preloadedModules = {}
local mockedModules = {}

local function requireActual(moduleName)
    if preloadedModules[moduleName] ~= nil then
        return preloadedModules[moduleName](moduleName)
    end

    return require(moduleName)
end

local function preloadRequireActual(moduleName, factory)
    preloadedModules[moduleName] = factory
end

local function setupModuleMocking()
    --- Search for modules in the test mocking environment.
    --- @param moduleName string
    --- @return any
    table.insert(package.loaders, function(moduleName)
        if mockedModules[moduleName] ~= nil then
            return mockedModules[moduleName]
        end

        -- Trim ./ or .\ from the start of the module name.
        moduleName = moduleName:gsub("^%.[/\\]", "")

        if mockedModules[moduleName] ~= nil then
            return mockedModules[moduleName]
        end

        return package.loaded[moduleName]
    end)
end

--- Mocks a module when it is required.
--- @param moduleName string
--- @param factory function
--- @param options table
local function mock(moduleName, factory, options)
    -- Trim ./ or .\ from the start of the module name.
    moduleName = moduleName:gsub("^%.[/\\]", "")

    local module = factory ~= nil and factory()
        or (package.loaded[moduleName] and package.loaded[moduleName] or {})

    setmetatable(module, mockFunctionLib.MOCK_FUNCTION_META)

    mockedModules[moduleName] = module

    if not package.loaded[moduleName] then
        package.loaded[moduleName] = module
    end
end

local function createMockFromModule(moduleName)
    local module = require(moduleName)

    -- Iterate all functions in the module and mock them.
    for key, value in pairs(module) do
        if type(value) == "function" then
            module[key] = mockFunctionLib.fn(value)
        end
    end

    mockedModules[moduleName] = module

    return module
end

--- TODO: This causes weird behaviour where modules are loaded multiple times and cant rely on local tables being the same instance.
local function resetModules()
    for moduleName, value in pairs(mockedModules) do
        setmetatable(value, nil)
        package.loaded[moduleName] = nil
    end

    mockedModules = {}
end

local function isolateModules(fn)
    local originalPackagePreload = package.preload
    local originalPackageLoaded = package.loaded
    package.preload = {}
    package.loaded = {}
    fn()
    package.loaded = originalPackageLoaded
    package.preload = originalPackagePreload
end

local function isolateModulesAsync(fn)
    --- @Not implemented (async)
end

return {
    mock = mock,
    doMock = mock,

    requireActual = requireActual,
    preloadRequireActual = preloadRequireActual,

    createMockFromModule = createMockFromModule,
    setupModuleMocking = setupModuleMocking,
    resetModules = resetModules,
    isolateModules = isolateModules,
    isolateModulesAsync = isolateModulesAsync,
}
