# Package
version = "0.4.3"
author = "Samantha Marshall"
description = "tool to spawn and exec commands with custom environments"
license = "BSD 3-Clause"

srcDir = "src/"
binDir = "build/"
bin = @["grimoire"]


# Dependencies
requires "nim >= 0.19.0"
requires "rune >= 0.5.4"
requires "parsetoml"
