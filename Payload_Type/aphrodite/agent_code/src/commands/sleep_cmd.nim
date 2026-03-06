import std/strutils

proc runSleep*(params: string, sleepInterval: var int, jitterPercent: var int): string =
  ## Update sleep interval and optional jitter.
  ## params format: '{"interval": 30, "jitter": 10}'
  ## or simple: "30" or "30 10"
  let parts = params.strip().split()
  if parts.len == 0 or parts[0].len == 0:
    return "Error: interval required"

  try:
    sleepInterval = parseInt(parts[0])
    if parts.len > 1:
      jitterPercent = parseInt(parts[1])
    result = "Sleep set to " & $sleepInterval & "s with " & $jitterPercent & "% jitter"
  except ValueError:
    result = "Error: invalid interval value"
