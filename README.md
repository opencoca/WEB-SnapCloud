# Codezy Snap!Cloud v1.0.0 - The Snap! Cloud
[![Build Status](https://travis-ci.org/opencoca/WEB-SnapCloud.svg?branch=master)](https://travis-ci.org/opencoca/WEB-SnapCloud)
[![License](https://img.shields.io/badge/license-GPL-purple.svg)](https://opensource.org/licenses/GPL-3.0)
[![GitHub stars](https://img.shields.io/github/stars/opencoca/WEB-SnapCloud.svg)](
[![GitHub issues](https://img.shields.io/github/issues/opencoca/WEB-SnapCloud.svg)](

## Now with RCLone support! (v1.0.0)

The Snap! Cloud is a backend for Snap<i>!</i> that stores only metadata in a database for reduced query response time, while storing actual contents in disk.

# Getting started

To get the latest version of the code, clone our repository:

Either using HTTPS:
```bash
git clone --depth 1 https://github.com/opencoca/WEB-SnapCloud
```
Or using SSH:
```bash
git clone --filter=tree:0 git@github.com:opencoca/WEB-SnapCloud.git
```

Then, cd to the directory and get started with our Makefile:
```bash
cd WEB-SnapCloud
make
```

This will show you the available commands. Make sure to install the submodules and the dependencies before running the server using `make this_dev_env`.

Then you can run the server using `make it_run` and access it at `http://localhost`.



## [Install](./INSTALL.md) And set things up.

## Use the Docker build to run things smoothly.

## Third party stuff
### Frameworks and tools
* [Leafo](http://leafo.net/)'s [Lapis](http://leafo.net/lapis/) is the lightweight, fast, powerful and versatile [Lua](http://lua.org) web framework that powers the Snap Cloud - [[ MIT ](https://opensource.org/licenses/MIT)]
* The [PostgreSQL](https://www.postgresql.org/) database holds almost all the data, while the rest is stored to disk. - [[ PostgreSQL license ](https://www.postgresql.org/about/licence/)]

### Lua rocks
* [Lubyk](https://github.com/lubyk)'s [XML](https://luarocks.org/modules/luarocks/xml) module is used to parse thumbnails and notes out of projects. - [[ MIT ](https://opensource.org/licenses/MIT)]
* [Michal Kottman](https://github.com/mkottman)'s [LuaCrypto](https://luarocks.org/modules/luarocks/luacrypto) module is the Lua frontend to the OpenSSL library. - [[ MIT ](https://opensource.org/licenses/MIT)]
* [Leafo](http://leafo.net/)'s [PgMoon](https://luarocks.org/modules/leafo/pgmoon) module is used to connect to the PostgreSQL database for migrations - [[ MIT ](https://opensource.org/licenses/MIT)]

### JS libraries
* [Matt Holt](https://github.com/mholt)'s [Papaparse](https://www.papaparse.com) library is used to parse CSV files for bulk account creation. - [[ MIT ](https://opensource.org/licenses/MIT)]
* [Eli Grey](https://github.com/eligrey)'s [FileSaver.js](https://github.com/eligrey/FileSaver.js/) library is used to save project files from the project page, and maybe elsewhere - [[ MIT ](https://opensource.org/licenses/MIT)]

### Did we forget to mention your stuff?
Sorry about that! Please file an issue stating what we forgot, or just send us a pull request modifying this [README](https://github.com/bromagosa/beetleCloud/edit/master/README.md).

### Live instance
The Snap!Cloud backend is currently live at [https://cloud.snap.berkeley.edu](https://cloud.snap.berkeley.edu). See the API description page at [https://cloud.snap.berkeley.edu/static/API](https://cloud.snap.berkeley.edu/static/API).

### Contributing
Please read [CONTRIBUTING.md](CONTRIBUTING.md) before sending us any pull requests. Thank you!
