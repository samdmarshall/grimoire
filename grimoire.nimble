# Package
version = "0.2.0"
author = "Samantha Marshall"
description = "tool to spawn and exec commands with custom environments"
license = "BSD 3-Clause"

srcDir = "src/"

bin = @["grimoire"]

skipExt = @["nim"]

# Dependencies
requires "nim >= 0.16.0"
requires "rune >= 0.3.0"
requires "parsetoml >= 0.2"
