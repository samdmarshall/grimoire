# =======
# Imports
# =======

import os
import tables
import logging
import sequtils
import strutils

import parsetoml

# =====
# Types
# =====

type
  Page* = object
    name*: string
    enabled*: bool
    defaultArguments*: string
    secureVariables*: seq[string]
    removeVariables*: seq[string]
    properties*: TableRef[string, string]

const
  StatusKey = "status"
  DefaultArgumentsKey = "arguments"
  SecureVariablesKey = "secure"
  RemoveVariablesKey = "remove"
  AdditionalVariablesKey = "additional"

const
  DefaultKeys = @[StatusKey, DefaultArgumentsKey, SecureVariablesKey, RemoveVariablesKey, AdditionalVariablesKey]

# =======
# Helpers
# =======

proc `$`*(page: Page): string =
  return "Page(" &
    "name: " & $page.name & ", " &
    "enabled: " & $page.enabled & ", " &
    "defaultArguments: " & $page.defaultArguments & ", " &
    "secureVariables: " & $page.secureVariables & ", " &
    "removeVariables: " & $page.removeVariables & ", " &
    "properties: " & $page.properties & ")"

# =========
# Functions
# =========

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

proc convertArray(value: seq[TomlValueRef]): seq[string] =
  var newseq = newSeq[string]()
  for item in value:
    newseq.add(convertValue(item))
  return newseq

proc convertTable(table: TomlTableRef): TableRef[string, string] =
  var newtable = newTable[string, string]()
  for key, value in pairs(table):
    debug("adding key: " & key & " and value: " & convertValue(value))
    newtable[key]= convertValue(value)
  return newtable

proc initPages*(config_path: string): seq[Page] =
  if not existsFile(config_path):
    echo("Unable to load settings file at path: " & config_path)
    quit(QuitFailure)

  var pages = newSeq[Page]()
  let settings = parseFile(config_path).getTable()
  for key in settings.keys():
    debug("processing page '" & key & "'...")
    let props = settings[key].getTable()

    let name = key
    debug("      name: " & key)

    let status =
      if props.hasKey(StatusKey): props[StatusKey].getBool()
      else:
        error("Found key '" & key & "' in config file without required '" &
          StatusKey & "' property!! As a result, this entry will be skipped...")
	      continue
    debug("   enabled: " & $status)

    let defaultArgs =
      if props.hasKey(DefaultArgumentsKey): convertString(props[DefaultArgumentsKey].stringVal)
      else: ""
    debug("arguments: '" & defaultArgs & "'")

    let secureVars =
      if props.hasKey(SecureVariablesKey): convertArray(props[SecureVariablesKey].arrayVal)
      else: @[]
    debug("   secure: [" & secureVars.join(", ") & "]")

    let removeVars =
      if props.hasKey(RemoveVariablesKey): convertArray(props[RemoveVariablesKey].arrayVal)
      else: @[]
    debug("   remove: [" & removeVars.join(", ") & "]")

    let additional =
      if props.hasKey(AdditionalVariablesKey): convertTable(props[AdditionalVariablesKey].getTable())
      else: newTable[string, string]()
    debug("  additional properties: " & $additional)

    let page = Page(name: name,
                    enabled: status,
                    defaultArguments: defaultArgs,
                    secureVariables: secureVars,
                    removeVariables: removeVars,
                    properties: additional)
    debug("Adding page '" & page.name & "' to index...")
    pages.add(page)

let unknownProperties = props.keys().keepItIf(it notin DefaultKeys)
if unknownProperties.len != 0:
  debug("While constructing page '" & page.name & "' found unknown keys in configuration!!")
  for key in unknownProperties:
    debug("  Unknown Key: '" & key & "', with value: '" & $(props[key]) & "' found.")

  debug("gathered all registered pages!")
  return pages
