# =======
# Imports
# =======

import os
import posix
import osproc
import tables
import strtabs
import strutils

import rune
import parsetoml

# =================
# Private Functions
# =================

proc convertValue(value: TomlValueRef): string =
  case value.kind
  of TomlValueKind.None:
    return ""
  of TomlValueKind.Int:
    return $(value.intVal)
  of TomlValueKind.Float:
    return $(value.floatVal)
  of TomlValueKind.Bool:
    return $(value.boolVal)
  of TomlValueKind.String:
    return value.stringVal
  else:
    discard

# ===========
# Entry Point
# ===========

let base_path =
  if not existsEnv("XDG_CONFIG_HOME"):
    getEnv("XDG_CONFIG_HOME")
  else:
    expandTilde("~/.config")
let grimoire_config_path = base_path.joinPath("grimoire/grimoire.toml")

if not existsFile(grimoire_config_path):
  echo("Unable to load settings file at path: " & grimoire_config_path)
  quit(QuitFailure)

var exec_command = ""
var command_arguments = newSeq[string]()
var first_argument = ""
let settings = parseFile(grimoire_config_path)

for item in commandLineParams():
  if len(first_argument) == 0:
    first_argument = item
  if len(exec_command) == 0:
    exec_command = item
  else:
    command_arguments.add(item)

if first_argument.startsWith("-"):
  case first_argument
  of "--list", "-l":
    for key in settings.keys():
      echo(key)
  of "--version", "-v":
    echo("grimoire v0.2.3")
  else:
    discard
  quit(QuitSuccess)

let config = initConfiguration()

var environment = newTable[string, string]()

for key, value in envPairs():
  environment[key] = value

for key in settings.keys():
  if key == exec_command:
    let section = settings[key].tableVal
    for prop in section.keys():
      case prop
      of "secure":
        let secure_variables = section[prop].arrayVal
        for variable in secure_variables:
          let variable_string = variable.stringVal
          environment[variable_string] = config.getRune(variable_string)
      of "remove":
        let remove_variables = section[prop].arrayVal
        for variable in remove_variables:
          let variable_string = variable.stringVal
          environment.del(variable_string)
      of "additional":
        let additional_variables_map = section[prop].tableVal
        for add_key, add_value in additional_variables_map:
          environment[add_key] = convertValue(add_value)
      else:
        discard

var environment_values = newStringTable()
for key, value in environment:
  environment_values[key] = value

if len(exec_command) > 0:
  let process = startProcess(exec_command, "",  command_arguments, environment_values, {poUsePath, poInteractive, poParentStreams})
  onSignal(SIGABRT, SIGINT, SIGTERM, SIGHUP, SIGQUIT, SIGTRAP):
    process.terminate()
  if process.waitForExit() != 0:
    quit(QuitFailure)

