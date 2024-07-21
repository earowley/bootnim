import    
  std/macros,
  ./core,
  ./protocols/[simpletextinput, simpletextoutput, pciio]
export
  pciio, simpletextinput, simpletextoutput

type
  # Represents any defined UEFI protocol.
  SomeEfiProtocol* = (
    PciIoProtocol | SimpleTextOutputProtocol | SimpleTextInputProtocol
  )

macro getProtocolGuid(t: static string): ptr Guid =
  let gname = ident(t & "Guid")
  quote do:
    `gname`.unsafeAddr

# Fetches a sequence of all protocols of a specific type.
proc protocols*[P: SomeEfiProtocol](t: typedesc[P]): seq[P] =
  let bs = gSystemTable.bootServices
  let guid = getProtocolGuid($t)
  result = cast[seq[P]](bs.protocolsByGuid(guid, gHandle))

