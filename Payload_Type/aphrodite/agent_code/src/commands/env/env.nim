import std/[os, json]
import core/types
import commands/registry

proc envExecute(taskId: string, params: JsonNode, state: AgentState,
                send: SendMsg): TaskResult =
  var entries = newJArray()
  for (key, val) in envPairs():
    entries.add(%*{"key": key, "value": val})
  return TaskResult(
    output:    $(%*{"env": entries}),
    status:    "success",
    completed: true)

proc initEnv*() =
  register("env", envExecute)
