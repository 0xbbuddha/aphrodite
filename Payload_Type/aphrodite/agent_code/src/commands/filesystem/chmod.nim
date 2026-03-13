import std/[os, json, strutils, osproc]
import core/types
import commands/registry
import crypto/strenc

proc chmodExecute(taskId: string, params: JsonNode, state: AgentState,
                  send: SendMsg): TaskResult =
  let path = params{"path"}.getStr("").strip()
  let mode = params{"mode"}.getStr("").strip()
  if path.len == 0 or mode.len == 0:
    return TaskResult(output: "Error: path and mode required",
                      status: "error", completed: true)

  let fullPath = if isAbsolute(path): path else: state.cwd / path
  try:
    when defined(windows):
      return TaskResult(output: "chmod not supported on Windows",
                        status: "error", completed: true)
    else:
      let (output, code) = execCmdEx("chmod " & mode & " " & quoteShell(fullPath),
                                      options = {poStdErrToStdOut})
      if code == 0:
        return TaskResult(output: "chmod " & mode & " " & fullPath,
                          status: "success", completed: true)
      else:
        return TaskResult(output: output.strip(), status: "error", completed: true)
  except Exception as e:
    return TaskResult(output: "Error: " & e.msg, status: "error", completed: true)

proc initChmod*() =
  register(hidstr("chmod"), chmodExecute)
