import std/[json, strutils]
import core/types
import core/jobs
import commands/registry

proc jobsExecute(taskId: string, params: JsonNode, state: AgentState,
                 send: SendMsg): TaskResult =
  let active = jobActiveList()
  if active.len == 0:
    return TaskResult(output: "No active jobs.", status: "success", completed: true)
  var lines: seq[string] = @["Active interactive jobs:"]
  for tid in active:
    let pid = jobPid(tid)
    lines.add("  task_id=" & tid & "  pid=" & $pid)
  return TaskResult(output: lines.join("\n"), status: "success", completed: true)

proc initJobs*() =
  register("jobs", jobsExecute)
