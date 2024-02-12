import std/strformat
import ../common


# The GUID for the PCI-I/O protocol.
let PciIOProtocolGuid* {.align(8).} = Guid(
  timeLow: 0x4cf5b200,
  timeMid: 0x68b8,
  timeHighAndVersion: 0x4ca5,
  clockSeqHighAndReserved: 0x9e,
  clockSeqLow: 0xec,
  node: [0xb2'u8, 0x3e'u8, 0x3f'u8, 0x50'u8, 0x02'u8, 0x9a'u8]
)


type
  Width {.size: sizeof(cint), pure.} = enum
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

  ConfigAccess = proc (this: PciIOProtocol, width: Width, offset: uint32, count: uint, buffer: pointer): EfiStatus {.cdecl.}
  MemoryAccess = proc (this: PciIOProtocol, width: Width, bar: uint8, offset: uint32, count: uint, buffer: pointer): EfiStatus {.cdecl.}

  ConfigRW {.byCopy.} = object
    read, write: ConfigAccess

  MemoryRW {.byCopy.} = object
    read, write: MemoryAccess

  PciIOProtocolImpl {.byCopy.} = object
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

  PciIOProtocol* = ptr PciIOProtocolImpl


proc device*(self: PciIOProtocol): uint16 =
  discard self.pci.read(self, Uint16, 0, 1, result.addr)


proc vendor*(self: PciIOProtocol): uint16 =
  discard self.pci.read(self, Uint16, 2, 1, result.addr)


proc uid*(self: PciIOProtocol): uint32 =
  (self.vendor.uint32 shl 16) or self.device


proc `$`*(self: PciIOProtocol): string =
  fmt"PCI Device  ({self.vendor:X}:{self.device:X})"
