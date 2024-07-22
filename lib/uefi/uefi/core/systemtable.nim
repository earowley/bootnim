import
  compose,
  ./[bootservicestable, runtimeservicestable],
  ../common,
  ../protocols/[simpletextinput, simpletextoutput]

type
  SystemTableObj {.byCopy.} = object
    hdr: EfiTableHeader
    firmwareVendor: ptr uint16
    firmwareRevision: uint32
    consoleInHandle: EfiHandle
    conIn: SimpleTextInputProtocol
    consoleOutHandle: EfiHandle
    conOut: SimpleTextOutputProtocol
    standardErrorHandle: EfiHandle
    stdErr: pointer
    runtimeServices: RuntimeServicesTable
    bootServices: BootServicesTable
    numberOfTableEntries: uint
    configurationTable: pointer
  SystemTable* = ptr SystemTableObj

getter SystemTable, hdr, header

# Get the global boot services table. If ExitBootServices has been
# called and the table is not available, this function will panic.
proc bootServices*(self: SystemTable): BootServicesTable =
  if likely(self.bootServices != nil):
    return self.bootServices

  # Can't throw an exception here because boot services are not available,
  # and any allocations will fail
  var err = L"Tried to access BS table after exiting boot services"
  self.conOut.writeString(err)

  while true:
    discard

# Get the global runtime services table.
proc runtimeServices*(self: SystemTable): RuntimeServicesTable =
  self.runtimeServices

# Get the UEFI firmware revision.
proc firmwareRevision*(self: SystemTable): uint32 =
  self.firmwareRevision

proc firmwareVendor*(self: SystemTable): string =
  let ua = cast[ptr UncheckedArray[uint16]](self.firmwareVendor)
  var i = 0

  while ua[i] != 0:
    result.add(char(ua[i]))
    inc i

# Get the SimpleTextInputProtocol for stdin.
proc conIn*(self: SystemTable): SimpleTextInputProtocol =
  self.conIn

# Get the SimpleTextOutputProtocol for stdout.
proc conOut*(self: SystemTable): SimpleTextOutputProtocol =
  self.conOut
