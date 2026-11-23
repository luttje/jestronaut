package.path = "./libs/?.lua;" .. package.path -- Try our local version first

os.exit(require "jestronaut/cli".run(args))
