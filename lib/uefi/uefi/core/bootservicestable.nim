import
  ../common

type
  EfiOpenProtocolAttrEnum {.size: sizeof(cint).} = enum
    opByHandleProtocol
    opGetProtocol
    opTestProtocol
    opByChildController
    opByDriver
    opExclusive
  EfiOpenProtocolAttr = set[EfiOpenProtocolAttrEnum]

  EfiLocateSearchType {.size: sizeof(cint), pure.} = enum
    AllHandles, ByRegisterNotify, ByProtocol

  WaitForEvent = proc (numberOfEvents: uint, event: ptr EfiEvent, index: ptr uint): EfiStatus {.cdecl.}
  AllocatePool = proc (poolType: EfiMemoryType, size: uint, buffer: pointer): EfiStatus {.cdecl.}
  FreePool = proc (buffer: pointer): EfiStatus {.cdecl.}
  CopyMem = proc (dst, src: pointer, length: uint) {.cdecl.}
  SetMem = proc (dst: pointer, size: uint, value: uint8) {.cdecl.}
  Exit = proc (imageHandle: EfiHandle, exitStatus: EfiStatus, exitDataSize: uint, exitData: pointer) {.cdecl.}
  LocateHandleBuffer = proc (searchType: EfiLocateSearchType, guid: ptr Guid, searchKey: pointer, noHandles: ptr uint, buffer: pointer): EfiStatus {.cdecl.}
  OpenProtocol = proc (handle: EfiHandle, guid: ptr Guid, iface: pointer, agentHandle, controllerHandle: EfiHandle, attributes: EfiOpenProtocolAttr): EfiStatus {.cdecl.}

  BootServicesTableObj {.byCopy.} = object
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
    loadImage: EfiImageUnload
    startImage: pointer
    exit: Exit
    unloadImage: EfiImageUnload
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
  BootServicesTable* = ptr BootServicesTableObj

# Use the protocols proc in the `uefi` module instead.
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
    if self.openProtocol(
      buffer[i],
      guid,
      p.addr,
      handle,
      cast[EfiHandle](nil),
      { opGetProtocol }
    ) != Success:
      continue
    result.add(p)

# Gets a protocol with the specified `guid` that is installed on `handle` using
# the specified `agent` handle. If the protocol is not installed on `handle`, nil
# is returned.
proc getProtocol*(
  self: BootServicesTable;
  guid: ptr Guid;
  handle, agent: EfiHandle
): pointer =
  if self.openProtocol(
    handle,
    guid,
    result.addr,
    agent,
    cast[EfiHandle](nil),
    { opGetProtocol }
  ) != Success:
    return nil

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
