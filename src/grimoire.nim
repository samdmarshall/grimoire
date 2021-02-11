# =======
# Imports
# =======

import os
import re
import times
import osproc
import logging
import sequtils
import strutils
import strformat

import runepkg/[ configuration, database, defaults ]
import parsetoml

import "commands.nim"
import "page.nim"

# =====
# Types
# =====

type
  EnvVar = object
    key: string
    value: string
    remove: bool

# =========
# Constants
# =========

const
  NimblePkgName {.strdefine.} = ""
  NimblePkgVersion {.strdefine.} = ""

  DefaultConfigurationPath = getConfigDir() / NimblePkgName / NimblePkgName.addFileExt("toml")

# =================
# Private Functions
# =================


proc usageInfo() =
  echo(fmt"Usage: {NimblePkgName}" & "\n" &
    "\t-v,--version        # prints version information\n" &
    "\t-h,--help\n" &
    "\t-?,--usage          # prints help/usage information\n" &
    "\t--verbose\n" &
    "\t--debug             # increases logged information verbosity\n" &
    "\t-c,--config <path>  # overrides the default config search path (~/.config/grimoire/)\n" &
    "\t-a,--list-all       # displays all registered applications\n" &
    "\t-e,--list-enabled   # displays enabled registered applications\n" &
    "\t-d,--list-disabled  # displays disabled registered applications\n" &
    "\t-E,--enable <app>   # toggles registered application to be enabled\n" &
    "\t-D,--disable <app>  # toggles registered application to be disabled\n")
  quit(QuitSuccess)

proc versionInfo() =
  echo(fmt"{NimblePkgName} v{NimblePkgVersion}")
  quit(QuitSuccess)

proc createEnvString(env: seq[EnvVar]): string =
  var remove = newSeq[string]()
  var insert = newSeq[string]()

  for item in env:
    if item.remove:
      remove.add(item.key)
    else:
      let value =
        case item.value
        of "true", "True": "1"
        of "false", "False": "0"
        else:
          "\"" & item.value & "\""

      insert.add(item.key & "=" & value)

  var output = " "
  if len(remove) > 0:
    output &= " -u " & remove.join(" ")
  if len(insert) > 0:
    output &= " " & insert.join(" ")
  return output


# ===========
# Entry Point
# ===========

proc main() =
  let config_path_dir = getConfigDir() / NimblePkgName
  var config_path = config_path_dir / NimblePkgName.addFileExt("toml")

  let log_path = config_path_dir / "logs" / NimblePkgName.addFileExt("log")
  var logger = newRollingFileLogger(log_path, levelThreshold = lvlDebug, bufSize = (1 * 1024 * 1024))
  #var logger = newConsoleLogger(levelThreshold = lvlDebug)
  addHandler(logger)
  info("New instance of " & NimblePkgName & " started at " & $now())
  var did_set_logging_flag = false

  let all_arguments = initArguments(commandlineParams())
  let arguments = all_arguments.filter(proc (x: Argument): bool = x.kind != atNone)
  debug("Parsed " & $len(arguments) & " arguments from command line")
  var exec_argument_index: int

  for arg in arguments:
    case arg.kind
    of atExec:
      exec_argument_index = arg.index
      break
    of atShortFlag, atLongFlag:
      if arg.flag in VersionFlags:
        versionInfo()
      elif arg.flag in HelpFlags or arg.flag in UsageFlags:
        usageInfo()
      elif arg.flag in ConfigFlags:
        config_path = arg.value
      elif arg.flag in VerboseFlags:
        setLogFilter(lvlNotice)
        did_set_logging_flag = true
      elif arg.flag in DebugFlags:
        setLogFilter(lvlDebug)
        did_set_logging_flag = true
      elif arg.flag in KnownFlags:
        continue
      else:
        error("Unknown flag '" & arg.flag & "' passed!")
    else:
      discard

  if not did_set_logging_flag:
    setLogFilter(lvlError)

  let contents = initPages(config_path)

  let args_end =
    if exec_argument_index < 0: int(arguments.high())
    else: exec_argument_index

  let grimoire_arguments = arguments.filter(proc (x: Argument): bool = x.index <= args_end)
  debug("found grimoire arguments: " & $grimoire_arguments)
  for arg in grimoire_arguments:
    case arg.kind
    of atShortFlag, atLongFlag:
      if arg.flag in ListAllFlags:
        contents.listAll()
      elif arg.flag in ListEnabledFlags:
        contents.listEnabled()
      elif arg.flag in ListDisabledFlags:
        contents.listDisabled()
      elif arg.flag in EnableFlags:
        contents.enable(arg.value)
      elif arg.flag in DisableFlags:
        contents.disable(arg.value)
      else:
        if arg.flag in KnownFlags:
          continue
        else:
          error("Unknown flag '" & arg.flag & "' passed to grimoire!!")
    else:
      discard

  let non_grimoire_arguments = arguments.filter(proc (x: Argument): bool = x.index >= exec_argument_index)
  if len(non_grimoire_arguments) == 0:
    fatal("no executable name found in arguments!")
    quit(QuitFailure)
  let exec_arg = non_grimoire_arguments[non_grimoire_arguments.low]

  let found_entries = contents.filter(proc (x: Page): bool = x.name == exec_arg.path)
  if len(found_entries) == 0:
    notice("No entry with name '" & exec_arg.path & "' found!")
    quit(QuitFailure)

  let entry = found_entries[0]

  var environment = newSeq[EnvVar]()

  let rune_config_path = resolveConfigPath(expandTilde("~/.config/rune/config.toml"), EnvVar_Config)
  if not fileExists(rune_config_path):
    echo(fmt"Unable to locate the configuration file, please create it at path: `~/.config/rune/config.toml` or define `{EnvVar_Config}` with the path value in your shell environment.")
    quit(QuitFailure)
  let vault = initConfiguration(rune_config_path)

  for token in entry.secureVariables:
    let envvar = EnvVar(key: token, value: vault.getRune(token), remove: false)
    environment.add(envvar)

  for token in entry.removeVariables:
    let envvar = EnvVar(key: token, value: "", remove: true)
    environment.add(envvar)

  for token in entry.properties.keys():
    let envvar = EnvVar(key: token, value: entry.properties[token], remove: false)
    environment.add(envvar)

  let exec_command = "env" & environment.createEnvString() & " " & exec_arg.path & " " & exec_arg.options

  quit(execCmd(exec_command))


when isMainModule:
  main()
