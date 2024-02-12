import ./common
import ./protocols/simpletextinput
import ./protocols/simpletextoutput

type
  MemoryType {.size: sizeof(cint), pure.} = enum
    Reserved
    LoaderCode
    LoaderData
    BootServicesCode
    BootServicesData
    RuntimeServicesCode
    RuntimeServicesData
    ConventionalMemory
    UnusableMemory
    ACPIReclaimMemory
    ACPIMemoryNVS
    MemoryMappedIO
    MemoryMappedIOPortSpace
    PalCode
    PersistentMemory
    Unaccepted
    Max

  LocateSearchType {.size: sizeof(cint), pure.} = enum
    AllHandles
    ByRegisterNotify
    ByProtocol

  OpenProtocolAttrE {.size: sizeof(cint), pure.} = enum
    ByHandleProtocol
    GetProtocol
    TestProtocol
    ByChildController
    ByDriver
    Exclusive
  OpenProtocolAttr = set[OpenProtocolAttrE]

  EfiTableHeader* {.byCopy.} = object
    signature*: uint64
    revision*: uint32
    headerSize*: uint32
    crc32*: uint32
    reserved: uint32

  SystemTableImpl {.byCopy.} = object
    hdr: EfiTableHeader
    firmwareVendor: ptr uint16
    firmwareRevision: uint32
    consoleInHandle: EfiHandle
    conIn: SimpleTextInputProtocol
    consoleOutHandle: EfiHandle
    conOut: SimpleTextOutputProtocol
    standardErrorHandle: EfiHandle
    stdErr: pointer
    runtimeServices: ptr RuntimeServicesTableImpl
    bootServices: ptr BootServicesTableImpl
    numberOfTableEntries: uint
    configurationTable: pointer

  WaitForEvent = proc (numberOfEvents: uint, event: ptr EfiEvent, index: ptr uint): EfiStatus {.cdecl.}
  AllocatePool = proc (poolType: MemoryType, size: uint, buffer: pointer): EfiStatus {.cdecl.}
  FreePool = proc (buffer: pointer): EfiStatus {.cdecl.}
  CopyMem = proc (dst, src: pointer, length: uint) {.cdecl.}
  SetMem = proc (dst: pointer, size: uint, value: uint8) {.cdecl.}
  Exit = proc (imageHandle: EfiHandle, exitStatus: EfiStatus, exitDataSize: uint, exitData: pointer) {.cdecl.}
  LocateHandleBuffer = proc (searchType: LocateSearchType, guid: ptr Guid, searchKey: pointer, noHandles: ptr uint, buffer: pointer): EfiStatus {.cdecl.}
  OpenProtocol = proc (handle: EfiHandle, guid: ptr Guid, iface: pointer, agentHandle, controllerHandle: EfiHandle, attributes: OpenProtocolAttr): EfiStatus {.cdecl.}

  BootServicesTableImpl {.byCopy.} = object
    hdr: EfiTableHeader
    raiseTPL: pointer
    restoreTPL: pointer
    allocatePages: pointer
    freePages: pointer
    getMemoryMap: pointer
    allocatePool: AllocatePool
    freePool: FreePool
    createEvent: pointer
    setTimer: pointer
    waitForEvent: WaitForEvent
    signalEvent: pointer
    closeEvent: pointer
    checkEvent: pointer
    installProtocolInterface: pointer
    reinstallProtocolInterface: pointer
    uninstallProtocolInterface: pointer
    handleProtocol: pointer
    reserved: pointer
    registerProtocolNotify: pointer
    locateHandle: pointer
    locateDevicePath: pointer
    installConfigurationTable: pointer
    loadImage: pointer
    startImage: pointer
    exit: Exit
    unloadImage: pointer
    exitBootServices: pointer
    getNextMonotonicCount: pointer
    stall: pointer
    setWatchdogTimer: pointer
    connectController: pointer
    disconnectController: pointer
    openProtocol: OpenProtocol
    closeProtocol: pointer
    openProtocolInformation: pointer
    protocolsPerHandle: pointer
    locateHandleBuffer: LocateHandleBuffer
    locateProtocol: pointer
    installMultipleProtocolInterfaces: pointer
    uninstallMultipleProtocolInterfaces: pointer
    calculateCrc32: pointer
    copyMem: CopyMem
    setMem: SetMem
    createEventEx: pointer

  RuntimeServicesTableImpl {.byCopy.} = object
    hdr: EfiTableHeader
    getTime: pointer
    setTime: pointer
    getWakeupTime: pointer
    setWakeupTime: pointer
    setVirtualAddressMap: pointer
    convertPointer: pointer
    getVariable: pointer
    getNextVariableName: pointer
    setVariable: pointer
    getNextHighMonotonicCount: pointer
    resetSystem: pointer
    updateCapsule: pointer
    queryCapsuleCapabilities: pointer
    queryVariableInfo: pointer

  SystemTable* = ptr SystemTableImpl
  BootServicesTable* = ptr BootServicesTableImpl
  RuntimeServicesTable* = ptr RuntimeServicesTableImpl
  SomeEfiTable* = SystemTable | BootServicesTable | RuntimeServicesTable
  
# Get the global boot services table. If ExitBootServices has been
# called and the table is not available, this function will panic.
proc bootServices*(self: SystemTable): BootServicesTable =
  if likely(self.bootServices != nil):
    return self.bootServices

  # Can't throw an exception here because boot services are not available,
  # and any allocations will fail
  const err = makeString("Tried to access BS table after exiting boot services")
  var verr = err
  self.conOut.writeString(verr)

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

# Get the header from some standard EFI table.
proc header*(self: SomeEfiTable): EfiTableHeader =
  self.hdr

# Use the protocols proc in efi/core instead.
proc protocolsByGuid*(self: BootServicesTable, guid: ptr Guid, handle: EfiHandle): seq[pointer] =
  var buffer: ptr UncheckedArray[EfiHandle]
  var size: uint
  var p: pointer

  if self.locateHandleBuffer(ByProtocol, guid, nil, size.addr, buffer.addr) != Success:
    return

  defer:
    discard self.freePool(buffer)

  result = newSeqOfCap[pointer](size)

  for i in 0..<size:
    if self.openProtocol(buffer[i], guid, p.addr, handle, cast[EfiHandle](nil), {GetProtocol}) != Success:
      continue
    result.add(p)

# Wait for the specified event.
proc waitForEvent*(self: BootServicesTable, event: EfiEvent) =
  var evt = [event]
  var idx: uint
  discard self.waitForEvent(1, evt[0].addr, idx.addr)

# Allocate `size` bytes and return the pointer to those bytes. Returns
# nil if the allocation fails.
proc alloc*(self: BootServicesTable, size: uint): pointer =
  if self.allocatePool(BootServicesData, size, result.addr) != Success:
    return nil

# Return memory allocated with `alloc` back to the system.
proc free*(self: BootServicesTable, p: pointer) =
  discard self.freePool(p)

# Exit the current program.
proc exit*(self: BootServicesTable, handle: EfiHandle, status: EfiStatus) {.noreturn.} =
  self.exit(handle, status, 0, nil)
