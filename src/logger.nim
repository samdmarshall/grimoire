# =======
# Imports
# =======

import os
import logging

import "common.nim"

# =========
# Functions
# =========

#[ === Public === ]#

proc initLogging*(): bool =
  var logger = newRollingFileLogger(DefaultConfigurationLogFile, bufSize = DefaultLogFileSize)
  addHandler(logger)
  info("New instance of (" & GrimoireName & " " & GrimoireVersion & ")" &
    " started at: " & $now() &
    " with PID: " & getCurrentProccessId()
  )
