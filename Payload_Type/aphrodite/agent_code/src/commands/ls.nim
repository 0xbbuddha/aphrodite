import std/[os, times, strformat, strutils]

proc runLs*(path: string, cwd: string): string =
  ## List files in directory. Returns formatted text output.
  var target = path
  if target.len == 0 or target == ".":
    target = if cwd.len > 0: cwd else: getCurrentDir()
  elif not isAbsolute(target):
    target = joinPath(if cwd.len > 0: cwd else: getCurrentDir(), target)

  if not dirExists(target):
    return "Error: directory not found: " & target

  var lines: seq[string]
  lines.add(fmt"Directory: {target}")
  lines.add("")

  try:
    for kind, path in walkDir(target):
      let info = getFileInfo(path)
      let name = lastPathPart(path)
      let size = if kind == pcFile: $info.size else: "<DIR>"
      let mtime = info.lastWriteTime.format("yyyy-MM-dd HH:mm")
      let typeChar = case kind
        of pcFile: "-"
        of pcDir: "d"
        of pcLinkToFile, pcLinkToDir: "l"
        else: "?"
      lines.add(fmt"{typeChar}  {mtime}  {size:>12}  {name}")
  except Exception as e:
    return "Error listing directory: " & e.msg

  result = lines.join("\n")
