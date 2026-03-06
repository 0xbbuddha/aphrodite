import std/[os, net, strutils, osproc]

proc getUsername*(): string =
  result = getEnv("USER", getEnv("LOGNAME", ""))
  if result.len == 0:
    when defined(windows):
      result = getEnv("USERNAME", "unknown")
    else:
      try:
        let (output, code) = execCmdEx("id -un")
        if code == 0:
          result = output.strip()
        else:
          result = "unknown"
      except:
        result = "unknown"

proc getHostname*(): string =
  try:
    let (output, code) = execCmdEx("hostname")
    if code == 0:
      result = output.strip()
    else:
      result = "unknown"
  except:
    result = "unknown"

proc getLocalIP*(): string =
  try:
    var sock = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
    sock.connect("8.8.8.8", Port(53))
    result = sock.getLocalAddr()[0]
    sock.close()
  except:
    result = "127.0.0.1"

proc getArch*(): string =
  when defined(amd64):
    result = "x86_64"
  elif defined(arm64):
    result = "aarch64"
  elif defined(i386):
    result = "x86"
  else:
    result = "unknown"

proc getOS*(): string =
  when defined(linux):
    result = "Linux"
  elif defined(windows):
    result = "Windows"
  elif defined(macosx):
    result = "macOS"
  else:
    result = "Unknown"

proc getPid*(): int =
  result = getCurrentProcessId()

proc debugLog*(msg: string) =
  when defined(debug):
    stderr.writeLine("[DBG] " & msg)
