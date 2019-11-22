# Package

version       = "0.1.1"
author        = "Xie Yanbo"
description   = "Nim library for scraping google search results"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["googlesearch"]


# Dependencies

requires "nim >= 1.0.0"
requires "nimquery >= 1.2.2"