import std/[os, json, osproc, strutils]
import core/types
import commands/registry

proc drivesExecute(taskId: string, params: JsonNode, state: AgentState,
                   send: SendMsg): TaskResult =
  try:
    var entries = newJArray()
    when defined(windows):
      for letter in 'A'..'Z':
        let drive = $letter & ":\\"
        if dirExists(drive):
          entries.add(%*{
            "filesystem": drive, "size": "", "used": "",
            "avail": "", "use_pct": "", "mount": drive,
          })
    else:
      let (raw, _) = execCmdEx("df -h", options = {poStdErrToStdOut})
      for line in raw.splitLines():
        let parts = line.splitWhitespace()
        if parts.len < 6: continue
        if parts[0] == "Filesystem": continue
        entries.add(%*{
          "filesystem": parts[0],
          "size":       parts[1],
          "used":       parts[2],
          "avail":      parts[3],
          "use_pct":    parts[4],
          "mount":      parts[5],
        })
    return TaskResult(
      output:    $(%*{"drives": entries}),
      status:    "success",
      completed: true)
  except Exception as e:
    return TaskResult(output: "Error: " & e.msg, status: "error", completed: true)

proc initDrives*() =
  register("drives", drivesExecute)
