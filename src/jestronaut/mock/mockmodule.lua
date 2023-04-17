local MOCK_FUNCTION_META = require "jestronaut.mock.mockfunction".MOCK_FUNCTION_META
local mockedModules = {}

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

  setmetatable(module, MOCK_FUNCTION_META)

  mockedModules[moduleName] = module
end

return {
  mock = mock,
  setupModuleMocking = setupModuleMocking,
}