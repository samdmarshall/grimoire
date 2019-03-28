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

import runepkg/lib
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
  VersionNumber = "v0.4.1"

# =================
# Private Functions
# =================

proc progName(): string =
  return getAppFilename().extractFilename()

proc usageInfo() =
  echo("Usage: " & progName() & "\n" &
    "\t-v,--version        # prints version information\n" &
    "\t-h,--help\n" &
    "\t-?,--usage          # prints help/usage information\n" &
    "\t--verbose\n" &
    "\t--debug             # increases logged information verbosity\n" &
    "\t-c,--config <path>  # overrides the default config search path (~/.config/grimoire)\n" &
    "\t-a,--list-all       # displays all registered applications\n" &
    "\t-e,--list-enabled   # displays enabled registered applications\n" &
    "\t-d,--list-disabled  # displays disabled registered applications\n" &
    "\t-E,--enable <app>   # toggles registered application to be enabled\n" &
    "\t-D,--disable <app>  # toggles registered application to be disabled\n")
  quit(QuitSuccess)

proc versionInfo() =
  echo(progName() & " " & VersionNumber)
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

let config_path_dir =  getEnv("XDG_CONFIG_HOME", "~/.config".expandTilde()) / progName()
var config_path = config_path_dir / addFileExt(progName(), "toml")

let log_path = config_path_dir / "logs" / addFileExt(progName(), "log")
var logger = newRollingFileLogger(log_path, bufSize = (1 * 1024 * 1024))
addHandler(logger)
info("New instance of " & progName() & " started at " & $now())

let arguments = initArguments(commandlineParams())
debug("Parsed " & $len(arguments) & " arguments from command line")
var exec_argument_index: uint = 0

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
    elif arg.flag in KnownFlags:
      continue
    else:
      error("Unknown flag '" & arg.flag & "' passed!")
  else:
    discard

let contents = initPages(config_path)

let args_end =
  if exec_argument_index == 0: uint(arguments.high())
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
let exec_arg = non_grimoire_arguments[0]

let found_entries = contents.filter(proc (x: Page): bool = x.name == exec_arg.path)
if len(found_entries) == 0:
  notice("No entry with name '" & exec_arg.path & "' found!")
  quit(QuitFailure)

let entry = found_entries[0]

var environment = newSeq[EnvVar]()
let vault: RuneConfiguration = initConfiguration()

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

