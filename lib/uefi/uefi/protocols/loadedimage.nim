import
  std/[strutils, sequtils],
  ../common
from std/unicode import add, Rune

let loadedImageProtocolGuid* {.align(8).} = Guid(
  timeLow: 0x5b1b31a1,
  timeMid: 0x9562,
  timeHighAndVersion: 0x11d2,
  clockSeqHighAndReserved: 0x8e,
  clockSeqLow: 0x3f,
  node: [0x00, 0xa0, 0xc9, 0x69, 0x72, 0x3b]
)

type
  LoadedImageProtocolObj = object
    revision: uint32
    parentHandle: EfiHandle
    systemTable: pointer
    deviceHandle: EfiHandle
    filePath: pointer
    reserved: pointer
    loadOptionsSize: uint32
    loadOptions: ptr UncheckedArray[uint16]
    imageBase: pointer
    imageSize: uint64
    imageCodeType, imageDataType: EfiMemoryType
    unload: EfiImageUnload
  LoadedImageProtocol* = ptr LoadedImageProtocolObj

# Converts this image to its string representation.
func `$`*(self: LoadedImageProtocol): string =
  "LoadedImageProtocol@$#" % [cast[uint](self.imageBase).toHex()]

# Iterates over the load options for this image as UCS-encoded wide characters.
iterator items*(self: LoadedImageProtocol): uint16 =
  let count = self.loadOptionsSize div sizeof(uint16).uint32 - 1
  for i in 0..<count:
    yield self.loadOptions[i]

# The load options for this image as a sequence of UCS-encoded wide characters.
func rawOptions*(self: LoadedImageProtocol): seq[uint16] =
  self.items().toSeq()

# The load options for this image, split by spaces. Does not parse quoted
# arguments.
func options*(self: LoadedImageProtocol): seq[string] =
  var opt: string
  for c in self:
    if c == uint16(' '):
      result.add(opt)
      opt.setLen(0)
      continue
    opt.add(Rune(c))
  if len(opt) > 0:
    result.add(opt)
