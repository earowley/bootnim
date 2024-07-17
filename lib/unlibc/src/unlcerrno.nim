var unlcerrno {.threadvar, volatile, exportc: "errno".}: cint

type Errors = enum
  EINTR = 4

func unlcstrerror(errnum: cint): ptr cchar {.exportc: "strerror", cdecl.} =
  cast[ptr cchar](
    case Errors(errnum)
    of EINTR:
      cstring"EINTR"
  )
