import std/[os, strutils]

proc runCat*(path: string, cwd: string): string =
  ## Read and return file contents.
  var target = path.strip()
  if target.len == 0:
    return "Error: file path required"

  if not isAbsolute(target):
    target = joinPath(if cwd.len > 0: cwd else: getCurrentDir(), target)

  if not fileExists(target):
    return "Error: file not found: " & target

  try:
    result = readFile(target)
  except Exception as e:
    result = "Error reading file: " & e.msg
