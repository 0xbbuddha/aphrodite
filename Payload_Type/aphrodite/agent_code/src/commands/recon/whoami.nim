import std/json
import core/types
import core/utils
import commands/registry

proc whoamiExecute(taskId: string, params: JsonNode, state: AgentState,
                   send: SendMsg): TaskResult =
  return TaskResult(
    output: getUsername() & "@" & getHostname(),
    status: "success",
    completed: true,
  )

proc initWhoami*() =
  register("whoami", whoamiExecute)
