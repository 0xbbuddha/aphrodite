import ../utils

proc runWhoami*(): string =
  let user = getUsername()
  let host = getHostname()
  result = user & "@" & host
