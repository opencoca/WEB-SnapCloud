package = "snapcloud"
version = "dev-0"

source = {
   url = "git+https://github.com/opencoca/snapCloud.git"
}

description = {
   summary = "A Project Server and API for Snap!.",
   detailed = [[
      This is currently in active development.
      Maybe this will say something witty one day.

      parent_maintainers =
      Bernat Romagosa, Michael Ball, Jens Mönig, Brian Harvey, Jadge Hügle
   ]],
   homepage = "https://snap.Startr.cloud",
   maintainer = "Startr LLC",
   license = "AGPL"
}

dependencies = {
   "lua ~> 5.1",
   "lapis == 1.14.0",
   "luaossl",
   "xml",
   "lua-resty-mail",
   "luasocket",
   "lua-resty-http",
   "lua-cjson",
   "luasec",
   "inspect",
   "luabitop"
}

build = {
    type = "none"
}
