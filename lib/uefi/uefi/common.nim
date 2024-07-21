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

  EfiMemoryType* {.size: sizeof(cint), pure.} = enum
    Reserved, LoaderCode, LoaderData, BootServicesCode, BootServicesData
    RuntimeServicesCode, RuntimeServicesData, ConventionalMemory
    UnusableMemory, AcpiReclaimMemory, AcpiMemoryNvs, MemoryMappedIo
    MemoryMappedIoPortSpace, PalCode, PersistentMemory, Unaccepted, Max

  EfiPciIoWidth* {.size: sizeof(cint), pure.} = enum
    Uint8
    Uint16
    Uint32
    Uint64
    FifoUint8
    FifoUint16
    FifoUint32
    FifoUint64
    FillUint8
    FillUint16
    FillUint32
    FillUint64
    Maximum

  EfiTableHeader* = object
    signature*: uint64
    revision*: uint32
    headerSize*: uint32
    crc32*: uint32
    reserved: uint32

func uefiString(s: static string): array[s.len + 1, uint16] =
  for i, c in s:
    result[i] = uint16(c)
  result[s.len] = uint16(0)

# Convert a static string literal to a UEFI "wide string". Only supports
# ASCII strings, and does not convert from UTF-8 to UTF-16.
template `w`*(s: static string): untyped =
  const result = uefiString(s)
  result

# Uses x86 `rdrand` to fetch a random number.
proc rdrand*: uint =
  asm """
    loop:
    rdrand %0
    jc out
    inc %1
    cmp $0x100000, %1
    jne loop
    out:
    : "=&r" (`result`)
    : "r" (0)
    : "cc"
  """
