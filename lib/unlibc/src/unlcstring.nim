proc unlcstrlen(p: ptr cchar): csize_t {.exportc: "strlen", cdecl.} =
  var i: uint = 0

  while p[i] != 0.cchar:
    inc i

  return i

proc unlcstrcmp(s1, s2: ptr cchar): cint {.exportc: "strcmp", cdecl.} =
  var i = 0

  while s1[i] != cchar(0) and s2[i] != cchar(0):
    if s1[i] != s2[i]:
      return cint(s1[i]) - cint(s2[i])

  cint(s1[i]) - cint(s2[i])

proc unlcmemchr(blk: pointer, c: cint, size: csize_t): pointer {.exportc: "memchr", cdecl.} =
  let haystack = cast[ptr uint8](blk)
  let needle = cast[uint8](c)

  for i in 0..<size:
    if haystack[i] == needle:
      return haystack[i].addr

proc memcpyInternal(dst, src: pointer, size: csize_t): pointer =
  let d = cast[ptr uint8](dst)
  let s = cast[ptr uint8](src)

  for i in 0..<size:
    d[i] = s[i]

  return dst

proc unlcmemcpy(dst, src: pointer, size: csize_t): pointer {.exportc: "memcpy", cdecl.} =
  if dst == nil or src == nil:
    return
  result = memcpyInternal(dst, src, size)

proc memsetInternal(dst: pointer, value: cint, num: csize_t): pointer =
  let p = cast[ptr uint8](dst)

  for i in 0..<num:
    p[i] = uint8(value)

  return dst

proc unlcmemset(dst: pointer, value: cint, num: csize_t): pointer {.exportc: "memset", cdecl.} =
  if dst == nil:
    return
  result = memsetInternal(dst, value, num)

proc unlcmemcmp(a1, a2: pointer, size: csize_t): cint {.exportc: "memcmp", cdecl.} =
  let
    b1 = cast[ptr cchar](a1)
    b2 = cast[ptr cchar](a2)

  for i in 0..<size:
    if b1[i] != b2[i]:
      return b1[i].cint - b2[i].cint

  return 0
