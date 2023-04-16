local requireActual = require
local mockedModules = {}

--- Overrides the require function to return a mocked module.
--- @param moduleName string
--- @return any
function require(moduleName)
  local module = mockedModules[moduleName]

  if module then
    return module
  end

  return requireActual(moduleName)
end

--- Mocks a module when it is required.
--- @param moduleName string
--- @param factory function
--- @param options table
local function mock(moduleName, factory, options)
  local module = factory ~= nil and factory() or function()
    print("Not yet implemented for mock Module with name " .. moduleName)
  end

  setmetatable(module, {
    __call = function(self, ...)
      return self
    end,
  })

  mockedModules[moduleName] = module
end

return {
  mock = mock,
  requireActual = requireActual,
}