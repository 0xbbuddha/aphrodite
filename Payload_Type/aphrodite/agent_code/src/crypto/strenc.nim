## strenc.nim — Compile-time XOR string obfuscation macro.
##
## Usage:
##   import crypto/strenc
##   let s = hidstr("my secret string")
##
## Each byte is XOR'd at compile time: k(i) = 0x5F xor byte((i * 7) and 0xFF)
## No plaintext string literal appears in the compiled binary.
import std/macros

macro hidstr*(s: static string): string =
  ## XOR-encodes each byte of `s` at compile time, decodes at runtime.
  ## Rolling key: k(i) = byte(0x5F) xor byte((i * 7) and 0xFF)
  let n = s.len
  if n == 0:
    return newLit("")
  let nLit = newLit(n)
  var arrNode = nnkBracket.newTree()
  for i in 0..<n:
    let k = byte(0x5F) xor byte((i * 7) and 0xFF)
    arrNode.add(newLit(byte(s[i]) xor k))
  result = quote do:
    block:
      const enc: array[`nLit`, byte] = `arrNode`
      var dec = newString(`nLit`)
      for i in 0..<`nLit`:
        dec[i] = char(enc[i] xor (byte(0x5F) xor byte((i * 7) and 0xFF)))
      dec
