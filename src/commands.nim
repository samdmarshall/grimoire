# =======
# Imports
# =======

import sets
import hashes
import logging
import parseopt
import sequtils

import "page.nim"


# =========
# Functions
# =========

proc initArguments*(input: seq[TaintedString]): seq[Argument] =
  var arguments = newSeq[Argument]()
  var counter: uint = 0
  var cmd = initOptParser(input)
  for kind, key, value in cmd.getopt():
    case kind:
      of cmdArgument:
        let arg = Argument(index: counter, kind: atExec, path: key, options: cmd.cmdLineRest())
        debug("parsed argument: " & arg.path & " with options: " & $arg.options & " at position: " & $arg.index) 
        arguments.add(arg)
        break
      of cmdShortOption:
        let arg = Argument(index: counter, kind: atShortFlag, flag: "-"&key, value: value)
        debug("parsed short flag: " & $arg.flag & " with value: " & $arg.value & " at position: " & $arg.index)
        arguments.add(arg)
      of cmdLongOption:
        let arg = Argument(index: counter, kind: atLongFlag, flag: "--"&key, value: value)
        debug("parsed long flag: " & $arg.flag & " with value: " & $arg.value & " at position: " & $arg.index)
        arguments.add(arg)
      else:
        discard
    debug("incrementing argument counter " & $counter & " -> " & $(counter + 1))
    inc(counter)
  info("successfully parsed " & $counter & " arguments!")
  return arguments

proc listAll*(contents: seq[Page]) =
  for page in contents:
    echo $page.name
  quit(QuitSuccess)

proc listEnabled*(contents: seq[Page]) =
  for page in contents:
    if page.enabled:
      echo $page.name
  quit(QuitSuccess)

proc listDisabled*(contents: seq[Page]) =
  for page in contents:
    if not page.enabled:
      echo $page.name
  quit(QuitSuccess)

proc enable*(contents: seq[Page], entry: string) =
  echo("Feature not yet supported!")
  quit(QuitFailure)

proc disable*(contents: seq[Page], entry: string) =
  echo("Feature not yet supported!")
  quit(QuitFailure)

