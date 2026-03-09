import std/[json, osproc, strutils]
import core/types
import commands/registry

proc psExecute(taskId: string, params: JsonNode, state: AgentState,
               send: SendMsg): TaskResult =
  let processes = newJArray()
  try:
    when defined(windows):
      # WMIC returns CSV: Node,CommandLine,ExecutablePath,Name,ParentProcessId,ProcessId
      let (raw, _) = execCmdEx(
        "wmic process get ProcessId,ParentProcessId,Name,CommandLine,ExecutablePath /format:csv",
        options = {poStdErrToStdOut})
      for line in raw.splitLines():
        let cols = line.strip().split(',')
        if cols.len < 6 or cols[0] == "Node" or cols[0].len == 0: continue
        var pid, ppid: int
        try: pid  = parseInt(cols[5]) except: pid  = 0
        try: ppid = parseInt(cols[4]) except: ppid = 0
        processes.add(%*{
          "process_id":        pid,
          "parent_process_id": ppid,
          "name":              cols[3],
          "bin_path":          cols[2],
          "command_line":      cols[1],
          "user":              "",
          "architecture":      "x64",
          "update_deleted":    true,
        })
    else:
      # ps -eo pid,ppid,user,comm,args --no-headers (Linux/macOS)
      let (raw, _) = execCmdEx("ps -eo pid,ppid,user,comm,args --no-headers",
                                options = {poStdErrToStdOut})
      for line in raw.splitLines():
        let s = line.strip()
        if s.len == 0: continue
        let parts = s.splitWhitespace(maxSplit = 4)
        if parts.len < 4: continue
        var pid, ppid: int
        try: pid  = parseInt(parts[0]) except: pid  = 0
        try: ppid = parseInt(parts[1]) except: ppid = 0
        let user    = parts[2]
        let name    = parts[3]
        let cmdline = if parts.len > 4: parts[4] else: name
        processes.add(%*{
          "process_id":        pid,
          "parent_process_id": ppid,
          "name":              name,
          "bin_path":          "",
          "command_line":      cmdline,
          "user":              user,
          "architecture":      "x64",
          "update_deleted":    true,
        })

    return TaskResult(
      output:      $(%*{"processes": processes}),
      status:      "success",
      completed:   true,
      extraFields: %*{"processes": processes},
    )
  except Exception as e:
    return TaskResult(output: "Error: " & e.msg, status: "error", completed: true)

proc initPs*() =
  register("ps", psExecute)
