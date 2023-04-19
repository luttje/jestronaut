local mockFunctionLib = require "jestronaut.mock.mockfunction"
local mockModuleLib = require "jestronaut.mock.mockmodule"

local function exposeTo(targetEnvironment)
  targetEnvironment.fn = function(targetEnvironment, fn)
    return mockFunctionLib.fn(fn)
  end

  targetEnvironment.mock = function(targetEnvironment, moduleName, factory, options)
    return mockModuleLib.mock(moduleName, factory, options)
  end

  targetEnvironment.createMockFromModule = function(targetEnvironment, moduleName)
    return mockModuleLib.createMockFromModule(moduleName)
  end

  targetEnvironment.isMockFunction = function(targetEnvironment, fn)
    return mockFunctionLib.isMockFunction(fn)
  end

  targetEnvironment.requireActual = function(targetEnvironment, moduleName)
    return require(moduleName)
  end
end

return {
  fn = mockFunctionLib.fn,
  exposeTo = exposeTo,

  mock = mockModuleLib.mock,
  createMockFromModule = mockModuleLib.createMockFromModule,
  isMockFunction = mockFunctionLib.isMockFunction,
  setupModuleMocking = mockModuleLib.setupModuleMocking,
}