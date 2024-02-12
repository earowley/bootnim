type  
  EfiHandle* = distinct pointer
  EfiEvent* = distinct EfiHandle
  EfiStatus* {.size: sizeof(uint), pure.} = enum
    Success
  Guid* {.byCopy.} = object
    timeLow*: uint32
    timeMid*: uint16
    timeHighAndVersion*: uint16
    clockSeqHighAndReserved*: uint8
    clockSeqLow*: uint8
    node*: array[6, uint8]

# Convert a static string literal to a UEFI "wide string".
func makeString*(s: static string): array[s.len + 1, uint16] =
  for i, c in s:
    result[i] = uint16(c)
  result[s.len] = uint16(0)

