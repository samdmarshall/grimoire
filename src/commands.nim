# =======
# Imports
# =======

import logging
import parseopt
import sequtils

import "page.nim"

# =====
# Types
# =====

type
  ArgType* = enum
    atNone,
    atExec,
    atShortFlag,
    atLongFlag

  Argument* = object
    index*: int
    case kind*: ArgType
    of atExec:
      path*: string
      options*: string
    of atShortFlag, atLongFlag:
      flag*: string
      value*: string
    of atNone:
      discard

# =========
# Constants
# =========

const
  VersionFlags* =      @["-v", "--version"]
  HelpFlags* =         @["-h", "--help"]
  UsageFlags* =        @["-?", "--usage"]
  ConfigFlags* =       @["-c", "--config"]
  ListAllFlags* =      @["-a", "--list-all"]
  ListEnabledFlags* =  @["-e", "--list-enabled"]
  ListDisabledFlags* = @["-d", "--list-disabled"]
  EnableFlags* =       @["-E", "--enable"]
  DisableFlags* =      @["-D", "--disable"]
  VerboseFlags* =      @["--verbose"]
  DebugFlags* =        @["--debug"]
  KnownFlags* = concat(VersionFlags, HelpFlags, UsageFlags, ConfigFlags, ListAllFlags, ListEnabledFlags, ListDisabledFlags, EnableFlags, DisableFlags, VerboseFlags, DebugFlags)

# =========
# Functions
# =========

proc initArguments*(input: seq[TaintedString]): seq[Argument] =
  result = newSeq[Argument]()
  var counter: int = 0
  var finished_parsing_arguments = false
  var cmd = initOptParser(input)
  for kind, key, value in cmd.getopt():
    var arg: Argument
    case kind
    of cmdArgument:
      if not finished_parsing_arguments:
        finished_parsing_arguments = true
      arg = Argument(index: counter, kind: atExec, path: key, options: cmd.cmdLineRest())
      debug("parsed argument: " & arg.path & " with options: " & $arg.options & " at position: " & $arg.index)
    of cmdShortOption:
      if not finished_parsing_arguments:
        arg = Argument(index: counter, kind: atShortFlag, flag: "-"&key, value: value)
        debug("parsed short flag: " & $arg.flag & " with value: " & $arg.value & " at position: " & $arg.index)
    of cmdLongOption:
      if not finished_parsing_arguments:
        if key == "":
          arg = Argument(index: counter, kind: atNone)
          debug("parsed separator at position: " & $arg.index)
          finished_parsing_arguments = true
        else:
          arg = Argument(index: counter, kind: atLongFlag, flag: "--"&key, value: value)
          debug("parsed long flag: " & $arg.flag & " with value: " & $arg.value & " at position: " & $arg.index)
    else:
      arg = Argument(index: counter, kind: atNone)
    result.add(arg)
    if finished_parsing_arguments and result[result.high()].kind == atExec:
      break
    debug("incrementing argument counter " & $counter & " -> " & $(counter + 1))
    inc(counter)
  info("successfully parsed " & $counter & " arguments!")

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

