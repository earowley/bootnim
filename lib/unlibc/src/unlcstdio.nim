const WriterBufLen = 255

type
  File = object
    fd: int

  StdoutWriter = object
    buffer: array[WriterBufLen + 1, uint16]
    index: uint

const
  stdinImpl = File(fd: 0)
  stdoutImpl = File(fd: 1)
  stderrImpl = File(fd: 2)

var
  unlcstdin {.exportc: "stdin".}: ptr File
  unlcstdout {.exportc: "stdout".}: ptr File
  unlcstderr {.exportc: "stderr".}: ptr File

proc doFlush(writer: var StdoutWriter) =
  writer.buffer[writer.index] = uint16(0)
  gSystemTable.conOut.writeString(writer.buffer)
  writer.index = 0

proc add(writer: var StdoutWriter, ucs: uint16) =
  writer.buffer[writer.index] = ucs
  inc writer.index

  if writer.index == WriterBufLen:
     writer.doFlush()

proc flush(writer: var StdoutWriter) =
  if writer.index == 0:
    return
  writer.doFlush()

proc unlcfwrite(data: pointer, size, count: csize_t, handle: pointer): csize_t {.exportc: "fwrite", cdecl.} =
  let file = cast[ptr File](handle)

  if file.fd == 0 or file.fd > 2:
    return 0

  let
    p = cast[ptr char](data)
    bytesToWrite = size * count
  var
    writer: StdoutWriter
    buf: string
  
  for i in 0..<bytesToWrite:
    buf.add(char(p[i]))

  for rune in runes(buf):
    let val = int32(rune)
    if val >= 0xD800:
      writer.add(uint16('?'))
      continue
    if val == int32('\n'):
      writer.add(uint16('\r'))
    writer.add(uint16(val))

  writer.flush()

  return bytesToWrite

proc unlcfgets(s: ptr cchar, count: cint, handle: pointer): ptr cchar {.exportc: "fgets", cdecl.} =
  let file = cast[ptr File](handle)

  if file.fd != 0:
    return nil

  var i: cint = 0
  var buffer: array[2, uint16]
  result = s

  while i < count - 1:
    let c = nextKey()

    if c == '\r':
      buffer[0] = uint16('\r')
      gSystemTable.conOut.writeString(buffer)
      buffer[0] = uint16('\n')
      gSystemTable.conOut.writeString(buffer)
      break
    elif c == '\b':
      if i > 0:
        dec i
      else:
        continue
    else:
      s[i] = cchar(c)
      inc i

    buffer[0] = uint16(c)
    gSystemTable.conOut.writeString(buffer)

  s[i] = cchar(0)

func unlcfflush(f: pointer): cint {.exportc: "fflush", cdecl.} = 0
func unlcferror(f: pointer): cint {.exportc: "ferror", cdecl.} = 0
func unlcclearerr(f: pointer) {.exportc: "clearerr", cdecl.} = discard
 
proc unlcsprintf(buffer, fmt: ptr cchar): cint {.exportc: "sprintf", varargs, cdecl.} =
  var i = 0
  let s = fmt.raw
  {.emit: """
  va_list va;
  va_start(va, fmt_p1);
  """.}

  while s[i] != char(0):
    let c = s[i]

    if c != '%':
      buffer[result] = cchar(c)
      inc result
      inc i
      continue

    if s[i + 1] == char(0):
      break
    if s[i + 1] == '%':
      buffer[result] = cchar('%')
      inc result
      i += 2
      continue

    inc i

    let (fs, width) = newFormatSpecifier(s[i].addr)
    let fill = if fs.pad == Zero: '0' else: ' '
    let alignLeft = fs.align == Left

    i += width

    case fs.kind
    of Signed:
      case fs.modifier
      of Unchanged, Char, Short:
        var arg: cint
        {.emit: "arg = va_arg(va, int);".}
        var lead = ""
        if arg > 0:
          if fs.lead == SignedPlus:
            lead = "+"
          elif fs.lead == SignedSpace:
            lead = " "
        result += cint(arg.writeToBuffer(fs.width, fill, alignLeft, 10, lead, false, buffer[result].addr.raw))
      of Long, LongLong:
        var arg: clonglong
        {.emit: "arg_2 = va_arg(va, long long);".}
        var lead = ""
        if arg > 0:
          if fs.lead == SignedPlus:
            lead = "+"
          elif fs.lead == SignedSpace:
            lead = " "
        result += cint(arg.writeToBuffer(fs.width, fill, alignLeft, 10, lead, false, buffer[result].addr.raw))
    of Binary:
      case fs.modifier
      of Unchanged, Char, Short:
        var arg: cuint
        {.emit: "arg_3 = va_arg(va, unsigned int);".}
        var lead = ""
        if fs.lead == BaseIdentifier:
          lead = "0b"
        result += cint(arg.writeToBuffer(fs.width, fill, alignLeft, 2, lead, false, buffer[result].addr.raw))
      of Long, LongLong:
        var arg: culonglong
        {.emit: "arg_4 = va_arg(va, unsigned long long);".}
        var lead = ""
        if fs.lead == BaseIdentifier:
          lead = "0b"
        result += cint(arg.writeToBuffer(fs.width, fill, alignLeft, 2, lead, false, buffer[result].addr.raw))
    of Octal:
      case fs.modifier
      of Unchanged, Char, Short:
        var arg: cuint
        {.emit: "arg_5 = va_arg(va, unsigned int);".}
        var lead = ""
        if fs.lead == BaseIdentifier:
          lead = "0o"
        result += cint(arg.writeToBuffer(fs.width, fill, alignLeft, 8, lead, false, buffer[result].addr.raw))
      of Long, LongLong:
        var arg: culonglong
        {.emit: "arg_6 = va_arg(va, unsigned long long);".}
        var lead = ""
        if fs.lead == BaseIdentifier:
          lead = "0o"
        result += cint(arg.writeToBuffer(fs.width, fill, alignLeft, 8, lead, false, buffer[result].addr.raw))
    of Unsigned:
      case fs.modifier
      of Unchanged, Char, Short:
        var arg: cuint
        {.emit: "arg_7 = va_arg(va, unsigned int);".}
        result += cint(arg.writeToBuffer(fs.width, fill, alignLeft, 10, "", false, buffer[result].addr.raw))
      of Long, LongLong:
        var arg: culonglong
        {.emit: "arg_8 = va_arg(va, unsigned long long);".}
        result += cint(arg.writeToBuffer(fs.width, fill, alignLeft, 10, "", false, buffer[result].addr.raw))
    of Hexadecimal:
      case fs.modifier
      of Unchanged, Char, Short:
        var arg: cuint
        {.emit: "arg_9 = va_arg(va, unsigned int);".}
        var lead = ""
        if fs.lead == BaseIdentifier:
          lead = "0x"
        result += cint(arg.writeToBuffer(fs.width, fill, alignLeft, 16, lead, fs.upper, buffer[result].addr.raw))
      of Long, LongLong:
        var arg: culonglong
        {.emit: "arg_10 = va_arg(va, unsigned long long);".}
        var lead = ""
        if fs.lead == BaseIdentifier:
          lead = "0x"
        result += cint(arg.writeToBuffer(fs.width, fill, alignLeft, 16, lead, fs.upper, buffer[result].addr.raw))
    of Double:
      var arg: cdouble
      {.emit: "arg_11 = va_arg(va, double);".}
      let pff = cast[float64](arg).pff
      let precision = if fs.precision == 0: 6 else: fs.precision
      result += cint(pff.writeToBuffer(fs.width, precision, fill, alignLeft, buffer[result].addr.raw))
    of Exponential:
      var arg: cdouble
      {.emit: "arg_12 = va_arg(va, double);".}
      let pff = cast[float64](arg).pff
      let precision = if fs.precision == 0: 6 else: fs.precision
      result += cint(pff.writeToBufferExp(fs.width, precision, fill, alignLeft, buffer[result].addr.raw))
    of Automatic:
      var arg: cdouble
      {.emit: "arg_13 = va_arg(va, double);".}
      let pff = cast[float64](arg).pff
      let tmp = arg.abs
      if tmp >= cdouble(100000) or tmp <= cdouble(0.00001):
        result += cint(pff.writeToBufferExp(fs.width, 3, fill, alignLeft, buffer[result].addr.raw))
      else:
        let precision = if fs.precision == 0: 6 else: fs.precision
        result += cint(pff.writeToBufferSmart(fs.width, precision, fill, alignLeft, buffer[result].addr.raw))
    of Fractional:
      var arg: cdouble
      {.emit: "arg_14 = va_arg(va, double);".}
      result += cint(cast[float64](arg).writeToBufferIEEE(fs.width, fill, alignLeft, buffer[result].addr.raw))
    of Character:
      var arg: int
      {.emit: "arg_15 = va_arg(va, int);".}
      buffer[result] = cchar(arg)
      inc result
    of String:
      var arg: ptr cchar
      {.emit: "arg_16 = va_arg(va, char *);".}
      var i = 0
      while arg[i] != cchar(0):
        buffer[result] = arg[i]
        inc i
        inc result
    of Pointer:
      var arg: csize_t
      {.emit: "arg_17 = va_arg(va, size_t);".}
      result += cint(arg.writeToBuffer(fs.width, fill, alignLeft, 16, "0x", true, buffer[result].addr.raw))
    of IntMax, PtrDiff:
      var arg: clonglong
      {.emit: "arg_18 = va_arg(va, long long);".}
      result += cint(arg.writeToBuffer(fs.width, fill, alignLeft, 10, "", false, buffer[result].addr.raw))
    of Size:
      var arg: csize_t
      {.emit: "arg_19 = va_arg(va, size_t);".}
      result += cint(arg.writeToBuffer(fs.width, fill, alignLeft, 10, "", false, buffer[result].addr.raw))

  buffer[result] = cchar(0)

  {.emit: "va_end(va);".}
