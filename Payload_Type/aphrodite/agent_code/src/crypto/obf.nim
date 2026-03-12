# obf.nim - Runtime string deobfuscation for compile-time encoded config values.
import nimcrypto/rijndael, nimcrypto/bcmode

proc xorDecode*(data: openArray[uint8], key: openArray[uint8]): string =
  result = newString(data.len)
  for i in 0..<data.len:
    result[i] = char(data[i] xor key[i mod key.len])

proc aesDecode*(data: openArray[uint8], key: openArray[uint8], iv: openArray[uint8]): string =
  ## AES-128-CBC decrypt with PKCS7 unpad.
  var keyArr: array[16, byte]
  var ivArr: array[16, byte]
  for i in 0..15:
    keyArr[i] = key[i]
    ivArr[i] = iv[i]
  var ctx: CBC[aes128]
  ctx.init(keyArr, ivArr)
  var buf = newSeq[byte](data.len)
  for i in 0..<data.len: buf[i] = data[i]
  var plain = newSeq[byte](data.len)
  ctx.decrypt(buf, plain)
  ctx.clear()
  let padLen = int(plain[^1])
  let textLen = plain.len - padLen
  result = newString(textLen)
  for i in 0..<textLen:
    result[i] = char(plain[i])
