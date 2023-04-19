local mockFunctionLib = require "jestronaut.mock.mockfunction"
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

  return module
end

return {
  mock = mock,
  createMockFromModule = createMockFromModule,
  setupModuleMocking = setupModuleMocking,
}