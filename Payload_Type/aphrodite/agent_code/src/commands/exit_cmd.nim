proc runExit*(running: var bool): string =
  running = false
  result = "Agent exiting."
