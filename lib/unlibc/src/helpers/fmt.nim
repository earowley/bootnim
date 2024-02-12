const
  Digits: set[char] = {'0'..'9'}
  F32ExBias = 127
  F64ExBias = 1023
  F32MantissaBits = 23
  F64MantissaBits = 52
  F32ExScalar = ln(float32(2)) / ln(float32(10))
  F64ExScalar = ln(float64(2)) / ln(float64(10))
  F32MantissaData = block:
    var res: array[F32MantissaBits, float32]
    var tmp = 2

    for i in 0..<res.len:
      res[i] = 1 / tmp
      tmp = tmp shl 1

    res
  F64MantissaData = block:
    var res: array[F64MantissaBits, float64]
    var tmp = 2

    for i in 0..<res.len:
      res[i] = 1 / tmp
      tmp = tmp shl 1

    res
  BaseCharactersUpper = block:
    var res: array[16, char]

    for i in 0..<10:
      res[i] = char(int('0') + i)
    for i in 0..<6:
      res[i + 10] = char(int('A') + i)

    res
  BaseCharactersLower = block:
    var res: array[16, char]

    for i in 0..<10:
      res[i] = char(int('0') + i)
    for i in 0..<6:
      res[i + 10] = char(int('a') + i)

    res

type PFF[F: SomeFloat] = object
  exp10: int
  norm: F

type NilTerminatedString* = (ptr char) | (ptr cchar) | cstring

type FormatAlignFlag = enum
  Right
  Left

type FormatPadFlag = enum
  Space
  Zero

type FormatLeadFlag = enum
  Empty
  SignedPlus
  SignedSpace
  BaseIdentifier

type FormatTypeModifier = enum
  Unchanged
  Char
  Short
  Long
  LongLong
  
type FormatType = enum
  Signed
  Binary
  Octal
  Unsigned
  Hexadecimal
  Double
  Exponential
  Automatic
  Fractional
  Character
  String
  Pointer
  IntMax
  PtrDiff
  Size

type FormatSpecifier = object
  align: FormatAlignFlag
  pad: FormatPadFlag
  lead: FormatLeadFlag
  width: int
  precision: int
  modifier: FormatTypeModifier
  kind: FormatType
  upper: bool

template raw(s: NilTerminatedString): ptr char =
  when typeof(s) is (ptr char):
    s
  else:
    cast[ptr char](s)
    
func normMantissa[F: SomeFloat](mantissa: int): F =
  when F is float32:
    const MantissaBits = F32MantissaBits
    const MantissaData = F32MantissaData
  elif F is float64:
    const MantissaBits = F64MantissaBits
    const MantissaData = F64MantissaData

  var man = mantissa
  var i = MantissaBits - 1

  while man > 0:
    if (man and 1) != 0:
      result += MantissaData[i]
    dec i
    man = man shr 1

  result += F(1.0)

func base10Exponent[F: SomeFloat](exponent: int): (int, F) =
  when F is float32:
    const Bias = F32ExBias
    const Scalar = F32ExScalar
  elif F is float64:
    const Bias = F64ExBias
    const Scalar = F64ExScalar

  let b10: F = F(exponent - Bias) * Scalar
  let b10i = int(b10)
  result = (b10i, pow(F(10), b10 - F(b10i)))

func pff[F: SomeFloat](f: F): PFF[F] =
  let comp = f.components
  let p2man = normMantissa[F](comp.mantissa)
  let (p10exp, p10scal) = base10Exponent[F](comp.exponent)
  result.norm = p2man * p10scal
  result.exp10 = p10exp
  if comp.negative:
    result.norm *= -1

proc unsignedToBuffer(value: uint, base: uint, upper: bool, buf: ptr char): int =
  var buffer: array[64, char]
  var idx = 0
  var tmp = value

  if upper:
    while tmp > 0:
      buffer[idx] = char(BaseCharactersUpper[tmp mod base])
      inc idx
      tmp = tmp div base
  else:
    while tmp > 0:
      buffer[idx] = char(BaseCharactersLower[tmp mod base])
      inc idx
      tmp = tmp div base

  result = idx
  var i = 0

  while idx > 0:
    buf[i] = buffer[idx - 1]
    dec idx
    inc i

proc writeToBuffer[F: SomeFloat](pff: PFF[F], width, precision: int, fill: char, alignLeft: bool, buf: ptr char): int =
  var exp = pff.exp10
  var norm = pff.norm
  var calcWidth = 0
  let negative = norm < F(0)

  if negative:
    inc calcWidth
    norm *= -1

  if norm > F(10):
    norm /= F(10)
    inc exp

  if exp < 0:
    calcWidth += 2 + precision
  else:
    calcWidth += 2 + exp + precision

  if buf == nil:
    return max(width, calcWidth)

  if fill != ' ' and negative:
    buf[result] = '-'
    inc result

  if not alignLeft and width > calcWidth:
    let bufferCount = width - calcWidth

    for i in 0..<bufferCount:
      buf[i] = fill

    result += bufferCount

  if fill == ' ' and negative:
    buf[result] = '-'
    inc result

  if exp < 0:
    buf[result] = '0'
    inc result
    buf[result] = '.'
    inc result

    var precCount = precision
    inc exp

    while exp < 0 and precCount > 0:
      buf[result] = '0'
      inc result
      inc exp
      dec precCount

    while precCount > 0:
      let last = int(norm)
      buf[result] = char(last + int('0'))
      norm -= F(last)
      norm *= F(10)
      inc result
      dec precCount
  else:
    for _ in 1..(exp+1):
      let last = int(norm)
      buf[result] = char(last + int('0'))
      norm -= F(last)
      norm *= F(10)
      inc result

    buf[result] = '.'
    inc result

    for _ in 1..precision:
      let last = int(norm)
      buf[result] = char(last + int('0'))
      norm -= F(last)
      norm *= F(10)
      inc result

  if alignLeft and width > calcWidth:
    let bufferCount = width - calcWidth

    for i in 0..<bufferCount:
      buf[result + i] = fill

    result += bufferCount

  assert result >= width

proc writeToBufferSmart[F: SomeFloat](pff: PFF[F], width, precision: int, fill: char, alignLeft: bool, buf: ptr char): int =
  var exp = pff.exp10
  var norm = pff.norm
  var calcWidth = 0
  var buffer: array[64, char]
  var bidx = 0
  var decLoc = 0
  let adjPrecision = min(16, precision)
  let negative = norm < F(0)

  if negative:
    inc calcWidth
    norm *= -1

  if norm > F(10):
    norm /= F(10)
    inc exp

  if exp < 0:
    buffer[bidx] = '0'
    inc bidx
    buffer[bidx] = '.'
    inc bidx

    var precCount = adjPrecision
    decLoc = bidx
    inc exp

    while exp < 0 and precCount > 0:
      buffer[bidx] = '0'
      inc bidx
      inc exp
      dec precCount

    while precCount > 0:
      let last = int(norm)
      buffer[bidx] = char(last + int('0'))
      norm -= F(last)
      norm *= F(10)
      inc bidx
      dec precCount
  else:
    for _ in 1..(exp+1):
      let last = int(norm)
      buffer[bidx] = char(last + int('0'))
      norm -= F(last)
      norm *= F(10)
      inc bidx

    buffer[bidx] = '.'
    inc bidx
    decLoc = bidx

    for _ in 1..adjPrecision:
      let last = int(norm)
      buffer[bidx] = char(last + int('0'))
      norm -= F(last)
      norm *= F(10)
      inc bidx

  calcWidth += decLoc
  let tmp = bidx

  while buffer[decLoc] == '0':
    inc decLoc
    inc calcWidth

  for i in decLoc..<tmp:
    if buffer[i] != '0':
      inc calcWidth
      continue
    if i == (bidx - 1):
      bidx = i
      break
    if buffer[i + 1] == '0':
      bidx = i
      break

    calcWidth += 2
    bidx = i + 2
    break

  if buf == nil:
    return max(width, calcWidth)

  if fill != ' ' and negative:
    buf[result] = '-'
    inc result

  if not alignLeft and width > calcWidth:
    let bufferCount = width - calcWidth

    for i in 0..<bufferCount:
      buf[i] = fill

    result += bufferCount

  if fill == ' ' and negative:
    buf[result] = '-'
    inc result

  for i in 0..<bidx:
    buf[result] = buffer[i]
    inc result

  if alignLeft and width > calcWidth:
    let bufferCount = width - calcWidth

    for i in 0..<bufferCount:
      buf[result + i] = fill

    result += bufferCount

  assert result >= width

proc writeToBufferExp[F: SomeFloat](pff: PFF[F], width, precision: int, fill: char, alignLeft: bool, buf: ptr char): int =
  var exp = pff.exp10
  var norm = pff.norm
  var calcWidth = 0
  let negative = norm < F(0)
  let negativeExp = exp < 0

  if negative:
    inc calcWidth
    norm *= -1

  if norm > F(10):
    norm /= F(10)
    inc exp

  if negativeExp:
    inc calcWidth
    exp *= -1

  calcWidth += 3 + precision + int(log10(F(exp))) + 1

  if buf == nil:
    return max(calcWidth, width)

  if fill != ' ' and negative:
    buf[result] = '-'
    inc result

  if not alignLeft and width > calcWidth:
    let bufferCount = width - calcWidth

    for i in 0..<bufferCount:
      buf[i] = fill

    result += bufferCount

  if fill == ' ' and negative:
    buf[result] = '-'
    inc result

  var last = int(norm)

  buf[result] = char(last + int('0'))
  inc result
  buf[result] = '.'
  inc result

  for _ in 1..precision:
    norm -= F(last)
    norm *= F(10)
    last = int(norm)
    buf[result] = char(last + int('0'))
    inc result

  buf[result] = 'E'
  inc result

  if negativeExp:
    buf[result] = '-'
    inc result

  result += unsignedToBuffer(uint(exp), 10, false, buf[result].addr)

  if alignLeft and width > calcWidth:
    let bufferCount = width - calcWidth

    for i in 0..<bufferCount:
      buf[result + i] = fill

    result += bufferCount

  assert result >= width

proc writeToBufferIEEE[F: SomeFloat](f: F, width: int, fill: char, alignLeft: bool, buf: ptr char): int =
  when F is float32:
    const Bias = F32ExBias
  elif F is float64:
    const Bias = F64ExBias

  let c = f.components
  var p2exp = c.exponent - Bias
  var mbuf: array[32, char]
  var mantissa = c.mantissa
  var calcWidth = 6
  var midx = 0
  let negativeExp = p2exp < 0

  if c.negative:
    inc calcWidth

  if negativeExp:
    p2exp *= -1

  calcWidth += int(log10(F(p2exp))) + 1
  
  while mantissa > 0:
    mbuf[midx] = BaseCharactersUpper[mantissa mod 16]
    mantissa = mantissa div 16
    inc midx

  var start = 0

  while start < midx:
    if mbuf[start] != '0':
      break
    inc start

  calcWidth += midx - start

  if buf == nil:
    return max(calcWidth, width)
  
  if fill != ' ' and c.negative:
    buf[result] = '-'
    inc result

  if not alignLeft and width > calcWidth:
    let bufferCount = width - calcWidth

    for i in 0..<bufferCount:
      buf[i] = fill

    result += bufferCount

  if fill == ' ' and c.negative:
    buf[result] = '-'
    inc result

  buf[result] = '0'
  inc result
  buf[result] = 'x'
  inc result
  buf[result] = '1'
  inc result
  buf[result] = '.'
  inc result

  while midx > start:
    buf[result] = mbuf[midx - 1]
    inc result
    dec midx

  buf[result] = 'P'
  inc result

  if negativeExp:
    buf[result] = '-'
  else:
    buf[result] = '+'

  inc result

  result += unsignedToBuffer(uint(p2exp), 10, false, buf[result].addr)

  if alignLeft and width > calcWidth:
    let bufferCount = width - calcWidth

    for i in 0..<bufferCount:
      buf[result + i] = fill

    result += bufferCount

  assert result >= width

proc writeToBuffer[I: SomeInteger](integer: I, width: int, fill: char, alignLeft: bool, base: uint, lead: string, upper: bool, buf: ptr char): int =
  assert base <= 16

  var calcWidth = 0
  var tmp = integer

  when I is SomeSignedInt:
    let negative = integer < 0
    if negative:
      inc calcWidth
      tmp *= I(-1)

  calcWidth += int(log(float(tmp), float(base))) + 1

  if buf == nil:
    return max(calcWidth, width)

  if fill != ' ':
    when I is SomeSignedInt:
      if negative:
        buf[result] = '-'
        inc result
    for c in lead:
      buf[result] = c
      inc result

  if not alignLeft and width > calcWidth:
    let bufferCount = width - calcWidth

    for i in 0..<bufferCount:
      buf[result + i] = fill
    result += bufferCount

  if fill == ' ':
    when I is SomeSignedInt:
      if negative:
        buf[result] = '-'
        inc result
    for c in lead:
      buf[result] = c
      inc result

  result += unsignedToBuffer(uint(tmp), base, upper, buf[result].addr)

  if alignLeft and width > calcWidth:
    let bufferCount = width - calcWidth

    for i in 0..<bufferCount:
      buf[result + i] = fill

    result += bufferCount

  assert result >= width

proc parseFmtInt(s: ptr char): (int, int) =
  var i = 0
  var num = 0

  while s[i] in Digits:
    num *= 10
    num += s[i].int - '0'.int
    inc i

  return (num, i)

proc newFormatSpecifier(stringy: NilTerminatedString): (FormatSpecifier, int) =
  let s = stringy.raw
  var i = 0

  while true:
    case s[i]
    of '-':
      result[0].align = Left
      inc i
    of '+':
      result[0].lead = SignedPlus
      inc i
    of ' ':
      result[0].lead = SignedSpace
      inc i
    of '#':
      result[0].lead = BaseIdentifier
      inc i
    of '0':
      result[0].pad = Zero
      inc i
    else:
      break

  while true:
    case s[i]
    of '.':
      let (tmp, sz) = parseFmtInt(s[i + 1].addr)
      result[0].precision = tmp
      i += 1 + sz
    elif s[i] in Digits:
      let (tmp, sz) = parseFmtInt(s[i].addr)
      result[0].width = tmp
      i += sz
    else:
      break

  while true:
    case s[i]
    of 'h':
      if s[i + 1] == 'h':
        result[0].modifier = Char
        i += 2
      else:
        result[0].modifier = Short
        inc i
    of 'l':
      if s[i + 1] == 'l':
        result[0].modifier = LongLong
        i += 2
      else:
        result[0].modifier = Long
        inc i
    of 'd', 'i':
      result[0].kind = Signed
      inc i
      break
    of 'b', 'B':
      result[0].kind = Binary
      inc i
      break
    of 'o':
      result[0].kind = Octal
      inc i
      break
    of 'u':
      result[0].kind = Unsigned
      inc i
      break
    of 'x':
      result[0].kind = Hexadecimal
      inc i
      break
    of 'X':
      result[0].kind = Hexadecimal
      result[0].upper = true
      inc i
      break
    of 'f', 'F':
      result[0].kind = Double
      inc i
      break
    of 'e', 'E':
      result[0].kind = Exponential
      inc i
      break
    of 'g', 'G':
      result[0].kind = Automatic
      inc i
      break
    of 'a', 'A':
      result[0].kind = Fractional
      inc i
      break
    of 'c':
      result[0].kind = Character
      inc i
      break
    of 's':
      result[0].kind = String
      inc i
      break
    of 'p':
      result[0].kind = Pointer
      inc i
      break
    of 'j':
      result[0].kind = IntMax
      inc i
      break
    of 't':
      result[0].kind = PtrDiff
      inc i
      break
    of 'z', 'Z':
      result[0].kind = Size
      inc i
      break
    else:
      assert false, "Bad format character: " & s[i]

  result[1] = i
