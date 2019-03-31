# =======
# Imports
# =======

import parseopt

import "common.nim"
import "logging.nim"

import
  "commands/version.nim"
  "commands/list.nim"
  "commands/enable.nim"
  "commands/disable.nim"

# =====
# Types
# =====

type
  GrimoireFlag = enum
    # Stop parsing arguments
    Halt = "--",

    # Version Flags
    Version_Short  = "-v",
    Version_Long   = "--version",
    DebugVersion   = "--debug-version",

    # Listing Registered Programs
    ListAll_Short      = "-l",
    ListAll_Long       = "--list-all",
    ListEnabled_Short  = "-e",
    ListEnabled_Long   = "--list-enabled",
    ListDisabled_Short = "-d",
    ListDisabled_Long  = "--list-disabled",

    # Help/Usage
    Usage_Short     = "-h",
    Usage_Short_Alt = "-?",
    Usage_Long      = "--help",
    Usage_Long_Alt  = "--usage",

    # Logging Verbosity
    Verbose        = "--verbose",
    Debug          = "--debug",

    # Enable/Disable Registered Programs
    Enable_Short   = "-E",
    Enable_Long    = "--enable",
    Disable_Short  = "-D",
    Disable_Long   = "--disable",

    # Configuration
    Config_Short = "-c"
    Config_Long  = "--config"

  ArgSource* = enum
    Unknown,
    CommandLineInput,
    ConfigDefaults

  ArgType* = enum
    Unknown,
    FlagAction,
    FlagProperty,
    FlagHalt,
    Path


  Argument* = object
    index*: uint
    source*: ArgSource
    case kind*: ArgType
    of FlagAction:
      key*: string
    of FlagProperty:
      key*: string
      value*: string
    of Path:
      path*: string
    else:
      discard

# =========
# Constants
# =========

const
  ShortNoVal_Flags = {'v', 'h', '?', 'l', 'e', 'd'}
  LongNoVal_Flags = @["version", "debug-version", "help", "usage", "list-all", "list-enabled", "list-disabled"]

# =========
# Functions
# =========

#[ === Private === ]#

proc parseArguments(p: OptParser, source: ArgSource): seq[Argument] =
  result = newSeq[Argument]()
  var counter: uint = 0
  while true:
    p.next()
    echo p.kind
    echo p.key
    echo p.val
#[ === Public === ]#

proc initArguments*(input: string, source: ArgSource = ConfigDefaults): seq[Argument] =
  var parser = initOptParser(cmdline = input, shortNoVal = ShortNoVal_Flags, longNoVal = LongNoVal_Flags)
  result = parseArguments(parser, source)

proc initArguments*(input: seq[TaintedString], source: ArgSource = CommandLineInput): seq[Argument] =
  var parser = initOptParser(cmdline = input, shortNoVal = ShortNoVal_Flags, longNoVal = LongNoVal_Flags)
  result = parseArguments(input, source)
