import
  std/strutils,
  ./common,
  ./core/[systemtable, bootservicestable, runtimeservicestable],
  ./protocols/[simpletextinput, simpletextoutput, loadedimage]
export
  common, systemtable, bootservicestable, runtimeservicestable,
  loadedimage

var gSystemTable*: SystemTable
var gHandle*: EfiHandle

# Converts a table header to a string.
func `$`*(self: EfiTableHeader): string =
  "(signature: $#, revision: $#, size: $#, crc32: $#)" % [
    toHex(self.signature), toHex(self.revision), $self.headerSize,
    toHex(self.crc32)
  ]

# Gets the loaded image protocol for the running image calling this
# function.
proc loadedImage*(): LoadedImageProtocol =
  result = cast[LoadedImageProtocol](gSystemTable.bootServices.getProtocol(
    loadedImageProtocolGuid.unsafeAddr,
    gHandle,
    gHandle
  ))
  assert(result != nil)

# Get a character from stdin.
proc nextKey*(): char =
  let bs = gSystemTable.bootServices
  bs.waitForEvent(gSystemTable.conIn.waitForKeyEvent)
  result = char(gSystemTable.conIn.readKey())

# Exit the process with the specified status.
proc exit*(status: EfiStatus) {.noreturn.} =
  gSystemTable.bootServices.exit(gHandle, status)

# Prints a UCS-2 wide string to the console. Is preferred to echo when
# possible as there is no need to convert from UTF-8 to UCS-2. If the
# input is not a wide string literal, it must be null terminated.
# If the string is not null terminated, a warning message is printed.
# Example: cout L"Hello, world!"
proc cout*(ws: openArray[uint16]) =
  const newline = ['\r'.uint16, '\n'.uint16, 0.uint16]

  if unlikely(ws[^1] != 0):
    cout L"Warning: attempted to print non-null-terminated string to cout"
    return

  gSystemTable.conOut.writeString(ws)

  if len(ws) < 3 or ws[^2] != uint16('\n'):
    gSystemTable.conOut.writeString(newline)
