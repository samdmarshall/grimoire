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
    secureVariables*: seq[string]
    removeVariables*: seq[string]
    properties*: TableRef[string, string]

# =======
# Helpers
# =======

proc `$`*(page: Page): string =
  return "Page(" & 
    "name: " & $page.name & ", " &
    "enabled: " & $page.enabled & ", " &
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

  result = newSeq[Page]()
  let settings = parseFile(config_path).getTable()
  for key in settings.keys():
    debug("processing page '" & key & "'...")
    let props = settings[key].getTable()

    let name = key
    debug("  name: " & key)

    let status = props["status"].getBool()
    debug("  enabled: " & $status)

    let secureVars =
      if props.hasKey("secure"): convertArray(props["secure"].arrayVal)
      else: @[]
    debug("  secure: [" & secureVars.join(", ") & "]")

    let removeVars =
      if props.hasKey("remove"): convertArray(props["remove"].arrayVal)
      else: @[]
    debug("  remove: [" & removeVars.join(", ") & "]")

    let additional =
      if props.hasKey("additional"): convertTable(props["additional"].getTable())
      else: newTable[string, string]()
    debug("  additional properties: " & $additional)

    let page = Page(name: name,
                    enabled: status,
                    secureVariables: secureVars,
                    removeVariables: removeVars,
                    properties: additional)
    debug("adding page '" & page.name & "' to index...")
    result.add(page)
  debug("gathered all registered pages!")

