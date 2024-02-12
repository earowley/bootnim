proc getAllocationSize(p: pointer): csize_t =
  cast[ptr csize_t](p)[-1]

proc setAllocationSize(p: pointer, size: csize_t) =
  cast[ptr csize_t](p)[-1] = size

proc unlcfree(p: pointer) {.exportc: "free".} =
  let ogPtr = cast[pointer](cast[uint](p) - uint(sizeof(uint)))
  gSystemTable.bootServices.free(ogPtr)

proc unlcmalloc(size: csize_t): pointer {.exportc: "malloc".} =
  result = gSystemTable.bootServices.alloc(uint(size) + uint(sizeof(uint)))

  if result == nil:
    return

  result = cast[pointer](cast[uint](result) + uint(sizeof(uint)))
  setAllocationSize(result, size)

proc unlccalloc(num, size: csize_t): pointer {.exportc: "calloc".} =
  let allocSize = num * size
  result = unlcmalloc(allocSize)

  if result != nil:
    discard unlcmemset(result, 0, allocSize)

proc unlcrealloc(p: pointer, size: csize_t): pointer {.exportc: "realloc".} =
  let currentSize = getAllocationSize(p)

  if size <= currentSize:
    return p

  result = unlcmalloc(size)

  if result == nil:
    return

  if unlcmemcpy(result, p, currentSize) == nil:
    unlcfree(result)
    return nil

  unlcfree(p)

proc unlcexit(status: cint) {.exportc: "exit", noreturn.} =
  exit(EfiStatus(status))
