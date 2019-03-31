# =======
# Imports
# =======

import
  "logging.nim"
  "config.nim"
  "cli.nim"

# ===========
# Entry Point
# ===========

when isMainModule:
  let arguments = initArguments(commandlineParams, ArgSource.CommandLineInput)

#[

import os
import re
import times
import osproc
import logging
import sequtils
import strutils

import runepkg/lib
import parsetoml

import "cli.nim"

import "cli.nim"
import "commands.nim"
import "page.nim"


# =====
# Types
# =====

type
  EnvVar = object
    key: string
    value: string
    secret: bool
    remove: bool

  Command = object
    environment: seq[EnvVar]
    executable: Argument
    defaultFlags: seq[Argument]


# =================
# Private Functions
# =================



proc createEnvString(env: seq[EnvVar]): string =
  var remove = newSeq[string]()
  var insert = newSeq[string]()

for item in env:
    if item.remove:
      remove.add(item.key)
    else:
      let value =
        case item.value.toLowerAscii()
        of  "true": "1"
        of "false": "0"
        else:
          "\"" & item.value & "\""

        insert.add(item.key & "=" & value)

var output = " "
  if len(remove) > 0:
    output &= " -u " & remove.join(" ")
  if len(insert) > 0:
    output &= " " & insert.join(" ")
  return output



let config_path_dir =  getEnv("XDG_CONFIG_HOME", "~/.config".expandTilde()) / progName()
var config_path = config_path_dir / addFileExt(progName(), "toml")


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
  let envvar = EnvVar(key: token, value: vault.getRune(token), secret: true, remove: false)
  environment.add(envvar)

for token in entry.removeVariables:
  let envvar = EnvVar(key: token, value: "", secret: false, remove: true)
  environment.add(envvar)

for token in entry.properties.keys():
  let envvar = EnvVar(key: token, value: entry.properties[token], secret: false, remove: false)
  environment.add(envvar)

let exec_command = "env" & environment.createEnvString() & " " & exec_arg.path & " " & entry.defaultArguments & " " & exec_arg.options

quit(execCmd(exec_command))

]#
