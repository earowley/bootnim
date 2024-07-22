import
  std/[options, algorithm, sequtils],
  ./protocols

var allDevices = none(seq[PciIoProtocol])

proc cmpDevices(a, b: PciIoProtocol): int =
  let ai = a.uid
  let bi = b.uid
  if ai > bi:
    return 1
  elif bi > ai:
    return -1
  return 0

proc initAllDevices: lent seq[PciIoProtocol] =
  var tmp = protocols(PciIOProtocol)
  sort(tmp, cmpDevices)
  allDevices = some(tmp)
  return allDevices.get()

# Fetch protocols for all PCI devices on the system.
proc fetchAllDevices*: lent seq[PciIoProtocol] =
  if allDevices.isSome:
    return allDevices.get()
  return initAllDevices()

# Find protocols for PCI devices that have the given vendor and device IDs.
proc findDevices*(vendor, device: uint16): seq[PciIoProtocol] =
  let all = fetchAllDevices()
  result = filterIt(all, it.device == device and it.vendor == vendor)
