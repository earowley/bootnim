import    
  std/[macros, strutils],
  ./core,
  ./protocols/[simpletextinput, simpletextoutput, pciio, loadedimage]
export
  pciio, simpletextinput, simpletextoutput, loadedimage

type
  # Represents any defined UEFI protocol.
  SomeEfiProtocol* = (
    PciIoProtocol | SimpleTextOutputProtocol | SimpleTextInputProtocol |
    LoadedImageProtocol
  )

macro getProtocolGuid(t: static string): ptr Guid =
  let gname = ident(toLowerAscii(t) & "Guid")
  quote do:
    `gname`.unsafeAddr

# Fetches a sequence of all protocols of a specific type.
proc protocols*[P: SomeEfiProtocol](t: typedesc[P]): seq[P] =
  let bs = gSystemTable.bootServices
  let guid = getProtocolGuid($t)
  result = cast[seq[P]](bs.protocolsByGuid(guid, gHandle))
