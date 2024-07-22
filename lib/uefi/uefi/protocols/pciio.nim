import
  std/strformat,
  ../common
export
  common

# The GUID for the PCI-I/O protocol.
let pciIoProtocolGuid* {.align(8).} = Guid(
  timeLow: 0x4cf5b200,
  timeMid: 0x68b8,
  timeHighAndVersion: 0x4ca5,
  clockSeqHighAndReserved: 0x9e,
  clockSeqLow: 0xec,
  node: [0xb2, 0x3e, 0x3f, 0x50, 0x02, 0x9a]
)

type
  ConfigAccess = proc (self: PciIoProtocol, width: EfiPciIoWidth, offset: uint32, count: uint, buffer: pointer): EfiStatus {.cdecl.}
  MemoryAccess = proc (self: PciIoProtocol, width: EfiPciIoWidth, bar: uint8, offset: uint32, count: uint, buffer: pointer): EfiStatus {.cdecl.}

  ConfigRW {.byCopy.} = object
    read, write: ConfigAccess

  MemoryRW {.byCopy.} = object
    read, write: MemoryAccess

  PciIoProtocolObj {.byCopy.} = object
    pollMem: pointer
    pollIO: pointer
    mem: MemoryRW
    io: MemoryRW
    pci: ConfigRW
    copyMem: pointer
    map: pointer
    unmap: pointer
    allocateBuffer: pointer
    freeBuffer: pointer
    flush: pointer
    getLocation: pointer
    attributes: pointer
    getBarAttributes: pointer
    setBarAttributes: pointer
    romSize: uint64
    romImage: pointer
  PciIoProtocol* = ptr PciIoProtocolObj

func typeToWidth[T](t: typedesc[T]): EfiPciIoWidth =
  when sizeof(T) mod 8 == 0:
    EfiPciIoWidth.Uint64
  elif sizeof(T) mod 4 == 0:
    EfiPciIoWidth.Uint32
  elif sizeof(T) mod 2 == 0:
    EfiPciIoWidth.Uint16
  else:
    EfiPciIoWidth.Uint8

func widthToNumber[T](t: typedesc[T], w: EfiPciIoWidth): uint =
  case w
  of EfiPciIoWidth.Uint64:
    sizeof(T) div 8
  of EfiPciIoWidth.Uint32:
    sizeof(T) div 4
  of EfiPciIoWidth.Uint16:
    sizeof(T) div 2
  else:
    sizeof(T)

# Read from PCI configuration space into a buffer variable `buf`.
proc cfgRead*[T](
  self: PciIoProtocol,
  offset: uint32,
  buf: var T
): EfiStatus =
  const width = typeToWidth(T)
  const count = widthToNumber(T, width)
  result = self.pci.read(self, width, offset, count, buf.addr)

# Write to PCI configuration space from a buffer variable `buf`.
proc cfgWrite*[T](
  self: PciIoProtocol,
  offset: uint32,
  val: T
): EfiStatus =
  const width = typeToWidth(T)
  const count = widthToNumber(T, width)
  var local = val
  result = self.pci.write(self, width, offset, count, local.addr)

# Read from MMIO address space into a buffer variable `buf`.
proc mmioRead*[T](
  self: PciIoProtocol,
  bar: uint8,
  offset: uint32,
  buf: var T
): EfiStatus =
  const width = typeToWidth(T)
  const count = widthToNumber(T, width)
  result = self.mem.read(self, width, bar, offset, count, buf.addr)

# Write to MMIO address space from a buffer variable `buf`.
proc mmioWrite*[T](
  self: PciIoProtocol,
  bar: uint8,
  offset: uint32,
  buf: T
): EfiStatus =
  const width = typeToWidth(T)
  const count = widthToNumber(T, width)
  var local = buf
  result = self.mem.write(self, width, bar, offset, count, local.addr)

# Gets the vendor ID of this device.
proc vendor*(self: PciIoProtocol): uint16 =
  discard self.cfgRead(0, result)

# Gets the device ID of this device.
proc device*(self: PciIoProtocol): uint16 =
  discard self.cfgRead(2, result)

# Gets the combined vendor ID and device ID of this device, uniquely identifying
# it.
proc uid*(self: PciIoProtocol): uint32 =
  (self.vendor.uint32 shl 16) or self.device

# Converts this device to its string representation.
proc `$`*(self: PciIoProtocol): string =
  fmt"PCI Device  ({self.vendor:X}:{self.device:X})"
