# Package
version = "0.4.1"
author = "Samantha Marshall"
description = "tool to spawn and exec commands with custom environments"
license = "BSD 3-Clause"

srcDir = "src/"

bin = @["grimoire"]

#skipExt = @["nim"]

# Dependencies
requires "nim >= 0.19.0"
requires "rune >= 0.5.3"
requires "parsetoml >= 0.2"
