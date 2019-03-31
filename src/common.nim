# =======
# Imports
# =======

import os

# =========
# Constants
# =========

const
  #[ === Info === ]#
  GrimoireName*    = "grimoire"
  GrimoireVersion* = "0.4.1"

  #[ === Configuration === ]#
  DefaultConfigurationDir*     = getConfigDir() / GrimoireName
  DefaultConfigurationFile*    = DefaultConfigurationDir / GrimoireName.addFileExt("toml")
  DefaultConfigurationLog*     = DefaultConfigurationDir / GrimoireName.addFileExt("log")

  #[ === Logging === ]#
  DefaultLogFileSize* = (1 * 1024 * 1024) # 1 megabyte


# =========
# Functions
# =========

proc initCommon*(): bool =
  if not DefaultConfigurationDir.existsOrCreateDir():
    DefaultConfiguration.createDir()
  result = DefaultConfigurationFile.existsFile()
