# =======
# Imports
# =======

import ../common.nim

# =========
# Functions
# =========

#[ === Public === ]#

## This method displays the regular version information, plus system and compile-time details.
proc debugVersion*(): int =
  let display_string =
    GrimoireName & " " & GrimoireVersion & "\n" &
      "Platform: " & HostOS & "\n" &
      "Architecture: " & HostCPU & "\n" &
      "Compiled on: " & CompileDate & "\n" &
      "Compiled at: " & CompileTime & "\n" &
      "Using Nim Version: " & NimVersion & "\n"

  echo(display_string)
  return QuitSuccess

## This method only displays the regular version information
proc version*(): int =
  let display_string =
    GrimoireName & " " & GrimoireVersion

  echo(display_string)
  return QuitSuccess
