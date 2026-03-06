import std/[base64, random]
import nimcrypto/rijndael, nimcrypto/bcmode, nimcrypto/hmac, nimcrypto/sha2

randomize()

proc pkcs7Pad*(data: seq[byte], blockSize: int = 16): seq[byte] =
  let padLen = blockSize - (data.len mod blockSize)
  result = newSeq[byte](data.len + padLen)
  if data.len > 0:
    copyMem(addr result[0], unsafeAddr data[0], data.len)
  for i in data.len ..< result.len:
    result[i] = byte(padLen)

proc pkcs7Unpad*(data: seq[byte]): seq[byte] =
  if data.len == 0:
    return data
  let padLen = int(data[^1])
  if padLen < 1 or padLen > 16 or padLen > data.len:
    return data
  result = data[0 ..< data.len - padLen]

proc toBytes*(s: string): seq[byte] =
  result = newSeq[byte](s.len)
  if s.len > 0:
    copyMem(addr result[0], unsafeAddr s[0], s.len)

proc fromBytes*(b: seq[byte]): string =
  result = newString(b.len)
  if b.len > 0:
    copyMem(addr result[0], unsafeAddr b[0], b.len)

proc aesEncrypt*(key: seq[byte], plaintext: string): seq[byte] =
  ## Encrypts plaintext with AES-256-CBC + HMAC-SHA256.
  ## Returns: IV(16) + ciphertext + HMAC(32)
  var iv = newSeq[byte](16)
  for i in 0..15:
    iv[i] = byte(rand(255))

  let plain = toBytes(plaintext)
  let padded = pkcs7Pad(plain)

  var keyArr: array[32, byte]
  let keyLen = min(32, key.len)
  copyMem(addr keyArr[0], unsafeAddr key[0], keyLen)

  var ivArr: array[16, byte]
  copyMem(addr ivArr[0], unsafeAddr iv[0], 16)

  var ctx: CBC[aes256]
  ctx.init(keyArr, ivArr)

  var ciphertext = newSeq[byte](padded.len)
  ctx.encrypt(padded, ciphertext)
  ctx.clear()

  # HMAC-SHA256 over IV + ciphertext
  let msgForMac = iv & ciphertext
  var macCtx: HMAC[sha256]
  macCtx.init(key)
  macCtx.update(msgForMac)
  let digest = macCtx.finish()

  # Result: IV + ciphertext + HMAC
  result = iv & ciphertext & @(digest.data)

proc aesDecrypt*(key: seq[byte], raw: seq[byte]): string =
  ## Decrypts a message in format: IV(16) + ciphertext + HMAC(32)
  ## Returns empty string on failure (HMAC mismatch or bad input).
  if raw.len < 48:  # 16 (IV) + 16 (min block) + 32 (HMAC) = 64 min, but allow smaller
    return ""
  if raw.len < 16 + 32:
    return ""

  let iv = raw[0..15]
  let ciphertext = raw[16 .. raw.len - 33]
  let sig = raw[raw.len - 32 .. ^1]

  # Verify HMAC
  let msgForMac = iv & ciphertext
  var macCtx: HMAC[sha256]
  macCtx.init(key)
  macCtx.update(msgForMac)
  let digest = macCtx.finish()

  var valid = true
  for i in 0..31:
    if digest.data[i] != sig[i]:
      valid = false
      break

  if not valid:
    return ""

  var keyArr: array[32, byte]
  let keyLen = min(32, key.len)
  copyMem(addr keyArr[0], unsafeAddr key[0], keyLen)

  var ivArr: array[16, byte]
  copyMem(addr ivArr[0], unsafeAddr iv[0], 16)

  var ctx: CBC[aes256]
  ctx.init(keyArr, ivArr)

  var plaintext = newSeq[byte](ciphertext.len)
  ctx.decrypt(ciphertext, plaintext)
  ctx.clear()

  result = fromBytes(pkcs7Unpad(plaintext))

proc base64Key*(keyB64: string): seq[byte] =
  ## Decode a base64-encoded AES key. Returns empty seq on failure.
  try:
    let decoded = base64.decode(keyB64)
    result = toBytes(decoded)
  except:
    result = @[]
