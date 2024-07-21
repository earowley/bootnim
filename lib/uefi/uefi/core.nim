import
  std/strutils,
  ./common,
  ./core/[systemtable, bootservicestable, runtimeservicestable],
  ./protocols/simpletextinput
export
  common, systemtable, bootservicestable, runtimeservicestable

var gSystemTable*: SystemTable
var gHandle*: EfiHandle

# Converts a table header to a string.
func `$`*(self: EfiTableHeader): string =
  "(signature: $#, revision: $#, size: $#, crc32: $#)" % [
    toHex(self.signature), toHex(self.revision), $self.headerSize,
    toHex(self.crc32)
  ]

# Get a character from stdin.
proc nextKey*(): char =
  let bs = gSystemTable.bootServices
  bs.waitForEvent(gSystemTable.conIn.waitForKeyEvent)
  result = char(gSystemTable.conIn.readKey())

# Exit the process with the specified status.
proc exit*(status: EfiStatus) {.noreturn.} =
  gSystemTable.bootServices.exit(gHandle, status)
