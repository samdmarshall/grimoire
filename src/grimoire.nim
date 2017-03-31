# =======
# Imports
# =======

import os
import posix
import osproc
import tables
import strtabs
import parsecfg
import strutils

import rune

# ===========
# Entry Point
# ===========

let base_path =
  if not existsEnv("XDG_CONFIG_HOME"):
    getEnv("XDG_CONFIG_HOME")
  else:
    expandTilde("~/.config")
let grimoire_config_path = base_path.joinPath("grimoire/grimoire.ini")

if not existsFile(grimoire_config_path):
  echo("Unable to load settings file at path: " & grimoire_config_path)
  quit(QuitFailure)

var exec_command = ""
var command_arguments = newSeq[string]()
var first_argument = ""
let settings = loadConfig(grimoire_config_path)

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
    echo("grimoire v0.2.2")
  else:
    discard
  quit(QuitSuccess)

let config = initConfiguration()

var environment = newStringTable(modeCaseSensitive)
for key, value in envPairs():
  environment[key] = value
if settings.hasKey(exec_Command):
  for key in settings[exec_command].keys():
    let value = settings.getSectionValue(exec_command, key)
    if len(value) == 0:
      let secure_value = config.getRune(key)
      if len(secure_value) > 0:
        environment[key] = secure_value
    else:
      environment[key] = value

if len(exec_command) > 0:
  let process = startProcess(exec_command, "",  command_arguments, environment, {poUsePath, poInteractive, poParentStreams})
  onSignal(SIGABRT, SIGINT, SIGTERM, SIGHUP, SIGQUIT, SIGTRAP):
    process.terminate()
  if process.waitForExit() != 0:
    quit(QuitFailure)
