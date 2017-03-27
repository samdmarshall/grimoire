# =======
# Imports
# =======

import os
import osproc
import tables
import strtabs
import parsecfg

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
var environment_name = ""
let settings = loadConfig(grimoire_config_path)

for item in commandLineParams():
  if len(environment_name) == 0:
    environment_name = item
  else:
    if len(exec_command) == 0:
      exec_command = item
    else:
      command_arguments.add(item)

if not settings.contains(environment_name):
  echo("No environment named '" & environment_name & "' is defined!")
  quit(QuitFailure)

let config = initConfiguration()

var environment = newStringTable(modeCaseSensitive)
for key, value in envPairs():
  environment[key] = value
for key in settings[environment_name].keys():
  let value = config.getRune(key)
  if len(value) > 0:
    environment[key] = value

let process = startProcess(exec_command, "",  command_arguments, environment, {poUsePath, poInteractive, poParentStreams})
if process.waitForExit() != 0:
  quit(QuitFailure)
