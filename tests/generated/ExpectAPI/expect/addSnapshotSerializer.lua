-- expect.addSnapshotSerializer



local tests = {

    (function()
        -- If you add a snapshot serializer in individual test files instead of adding it to `snapshotSerializers` configuration:
        --
        -- - You make the dependency explicit instead of implicit.
        -- - You avoid limits to configuration that might cause you to eject from [create-react-app](https://github.com/facebookincubator/create-react-app).
        local ____exports = {}
        local ____my_2Dserializer_2Dmodule = require("my-serializer-module")
        local serializer = ____my_2Dserializer_2Dmodule.default
        expect:addSnapshotSerializer(serializer)
        return ____exports
    end)(),



}

return tests
