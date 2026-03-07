import std/[json, osproc]
import core/types
import commands/registry

proc netstatExecute(taskId: string, params: JsonNode, state: AgentState,
                    send: SendMsg): TaskResult =
  try:
    var output = ""
    when defined(windows):
      let (out1, _) = execCmdEx("netstat -ano", options = {poStdErrToStdOut})
      output = out1
    else:
      let (out1, code1) = execCmdEx("ss -tunap", options = {poStdErrToStdOut})
      if code1 == 0:
        output = out1
      else:
        let (out2, _) = execCmdEx("netstat -tunap", options = {poStdErrToStdOut})
        output = out2
    return TaskResult(output: output, status: "success", completed: true)
  except Exception as e:
    return TaskResult(output: "Error: " & e.msg, status: "error", completed: true)

proc initNetstat*() =
  register("netstat", netstatExecute)
