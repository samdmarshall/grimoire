# =======
# Imports
# =======

import os
import osproc
import tables
import strutils

import rune
import parsetoml

# =========
# Constants
# =========

const
  KnownArguments = @[
    "--list", 
    "-l", 
    "--version", 
    "-v"
  ]

# =====
# Types
# =====

type
  EnvVar = object
    key: string
    value: string
    remove: bool

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
    return ""

proc parseGrimoireArgument(item: TaintedString, own_args: bool): bool =
  if own_args:
    return KnownArguments.contains(item)
  return false

proc createEnvString(env: seq[EnvVar]): string =
  var remove = newSeq[string]()
  var insert = newSeq[string]()
  
  for item in env:
    if item.remove:
      remove.add(item.key)
    else:
      insert.add(item.key & "=" & item.value)

  var output = " "
  if len(remove) > 0:
    output &= " -u " & remove.join(" ")
  if len(insert) > 0:
    output &= " " & insert.join(" ")
  return output

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

let settings = parseFile(grimoire_config_path).getTable()
var own_arguments = newSeq[string]()
var command_arguments = newSeq[string]()

for item in commandlineParams():
  let still_parsing_grimoire_args = len(command_arguments) == 0
  if parseGrimoireArgument(item, still_parsing_grimoire_args):
    own_arguments.add(item)
  else:
    command_arguments.add(item)

for arg in own_arguments:
  case arg
  of "--list", "-l":
    for key,val in settings.pairs():
      echo(key)
  of "--version", "-v":
    echo("grimoire v0.3")
  else:
    discard
  quit(QuitSuccess)

let config = initConfiguration()

var environment = newSeq[EnvVar]()

if len(command_arguments) > 0:
  let exec_command = command_arguments[0]

  if settings.hasKey(exec_command):
    let section = settings[exec_command].tableVal
    for prop in section.keys():
      case prop
      of "secure":
        let secure_variables = section[prop].arrayVal
        for variable in secure_variables:
          let variable_string = variable.stringVal
          let add_var = EnvVar(key: variable_string, value: config.getRune(variable_string))
          environment.add(add_var)
      of "remove":
        let remove_variables = section[prop].arrayVal
        for variable in remove_variables:
          let variable_string = variable.stringVal
          let remove_var = EnvVar(key: variable_string, remove: true)
          environment.add(remove_var)
      of "additional":
        let additional_variables_map = section[prop].tableVal
        for add_key, add_value in additional_variables_map:
          let new_var = EnvVar(key: add_key, value: convertValue(add_value))
          environment.add(new_var)
      else:
        discard

  var exec_string = "env" & createEnvString(environment) & " " & command_arguments.join(" ")
  quit(execCmd(exec_string))
