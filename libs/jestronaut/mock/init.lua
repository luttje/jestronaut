local mockFunctionLib = require "jestronaut/mock/mockfunction"
local mockModuleLib = require "jestronaut/mock/mockmodule"

local function exposeTo(targetEnvironment)
    targetEnvironment.fn = function(targetEnvironment, fn)
        return mockFunctionLib.fn(fn)
    end

    targetEnvironment.replaceProperty = function(targetEnvironment, object, propertyName, value)
        return mockFunctionLib.replaceProperty(object, propertyName, value)
    end

    targetEnvironment.spyOn = function(targetEnvironment, object, methodName, accessType)
        return mockFunctionLib.spyOn(object, methodName, accessType)
    end

    targetEnvironment.mock = function(targetEnvironment, moduleName, factory, options)
        return mockModuleLib.mock(moduleName, factory, options)
    end

    targetEnvironment.doMock = function(targetEnvironment, moduleName, factory, options)
        return mockModuleLib.doMock(moduleName, factory, options)
    end

    targetEnvironment.createMockFromModule = function(targetEnvironment, moduleName)
        return mockModuleLib.createMockFromModule(moduleName)
    end

    targetEnvironment.isMockFunction = function(targetEnvironment, fn)
        return mockFunctionLib.isMockFunction(fn)
    end

    targetEnvironment.requireActual = function(targetEnvironment, moduleName)
        return mockModuleLib.requireActual(moduleName)
    end

    targetEnvironment.preloadRequireActual = function(targetEnvironment, moduleName, factory)
        return mockModuleLib.preloadRequireActual(moduleName, factory)
    end

    targetEnvironment.resetModules = function(targetEnvironment)
        return mockModuleLib.resetModules()
    end

    targetEnvironment.isolateModules = function(targetEnvironment, fn)
        return mockModuleLib.isolateModules(fn)
    end

    targetEnvironment.isolateModulesAsync = function(targetEnvironment, fn)
        return mockModuleLib.isolateModulesAsync(fn)
    end

    targetEnvironment.restoreAllMocks = function(targetEnvironment)
        return mockFunctionLib.restoreAllMocks()
    end
end

return {
    fn = mockFunctionLib.fn,
    exposeTo = exposeTo,

    mock = mockModuleLib.mock,
    doMock = mockModuleLib.doMock,
    createMockFromModule = mockModuleLib.createMockFromModule,
    isMockFunction = mockFunctionLib.isMockFunction,
    setupModuleMocking = mockModuleLib.setupModuleMocking,
}
