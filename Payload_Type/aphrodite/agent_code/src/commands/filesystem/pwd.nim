import std/json
import core/types
import commands/registry

proc pwdExecute(taskId: string, params: JsonNode, state: AgentState,
                send: SendMsg): TaskResult =
  return TaskResult(output: state.cwd, status: "success", completed: true)

proc initPwd*() =
  register("pwd", pwdExecute)
