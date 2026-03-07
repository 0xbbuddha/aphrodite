import std/[os, json, strutils]
import core/types
import commands/registry

proc catExecute(taskId: string, params: JsonNode, state: AgentState,
                send: SendMsg): TaskResult =
  let path = params{"path"}.getStr("").strip()
  if path.len == 0:
    return TaskResult(output: "Error: path required", status: "error", completed: true)

  let fullPath = if isAbsolute(path): path else: state.cwd / path
  if not fileExists(fullPath):
    return TaskResult(output: "File not found: " & fullPath,
                      status: "error", completed: true)
  try:
    return TaskResult(output: readFile(fullPath), status: "success", completed: true)
  except Exception as e:
    return TaskResult(output: "Error: " & e.msg, status: "error", completed: true)

proc initCat*() =
  register("cat", catExecute)
