import std/macros
import ./common
import ./tables
import ./protocols/simpletextinput
import ./protocols/simpletextoutput
from ./protocols/pciio import PciIOProtocol

export common
export tables

type
  SomeEfiProtocol* = (
    PciIOProtocol | SimpleTextOutputProtocol | SimpleTextInputProtocol
  )

var gSystemTable*: SystemTable
var gHandle*: EfiHandle

# Get a character from stdin.
proc nextKey*(): char =
  let bs = gSystemTable.bootServices
  bs.waitForEvent(gSystemTable.conIn.waitForKey)
  result = char(gSystemTable.conIn.readKey())

macro getProtocolGuid(t: static string): ptr Guid =
  let gname = ident(t & "Guid")
  quote do:
    `gname`.unsafeAddr
    
proc protocols*[P: SomeEfiProtocol](t: typedesc[P]): seq[P] =
  let bs = gSystemTable.bootServices
  let guid = getProtocolGuid($t)
  result = cast[seq[P]](bs.protocolsByGuid(guid, gHandle))

proc exit*(status: EfiStatus) {.noreturn.} =
  gSystemTable.bootServices.exit(gHandle, status)
