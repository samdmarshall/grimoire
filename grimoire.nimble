# Package
version = "0.1"
author = "Samantha Marshall"
description = "tool to spawn and exec commands with custom environments"
license = "BSD 3-Clause"

srcDir = "src/"

bin = @["grimoire"]

skipExt = @["nim"]

# Dependencies
requires "nim >= 0.16.0"
requires "rune"
requires "parsetoml >= 0.2"
