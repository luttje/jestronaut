  return {
    name = "luttje/jestronaut",
    version = "0.1.0",
    description = "Library for testing your Lua scripts.",
    tags = { "test", "jest", "automated" },
    license = "MIT",
    author = { name = "luttje", email = "2738114+luttje@users.noreply.github.com" },
    homepage = "https://github.com/luttje/jestronaut",
    dependencies = {
      "luvit/require",
    },
    files = {
      "libs/**.lua",
      "main.lua",
      "package.lua"
    }
  }
  