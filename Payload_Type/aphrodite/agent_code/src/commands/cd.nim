import std/[os, strutils]

proc runCd*(path: string, cwd: var string): string =
  ## Changes the agent's working directory. Updates cwd in place.
  var target = path.strip()
  if target.len == 0:
    return "Error: path required"

  if not isAbsolute(target):
    target = joinPath(if cwd.len > 0: cwd else: getCurrentDir(), target)

  # Normalize the path
  target = normalizedPath(target)

  if not dirExists(target):
    return "Error: directory not found: " & target

  cwd = target
  result = "Changed directory to: " & cwd
