import std/options
import std/algorithm
import ./core
import ./protocols/pciio
export pciio

var allDevices = none(seq[PciIOProtocol])

proc cmpDevices(a, b: PciIOProtocol): int =
  let ai = a.uid
  let bi = b.uid
  if ai > bi:
    return 1
  elif bi > ai:
    return -1
  return 0

proc initAllDevices: lent seq[PciIOProtocol] =
  var tmp = protocols(PciIOProtocol)
  sort(tmp, cmpDevices)
  allDevices = some(tmp)
  return allDevices.get()

proc fetchAllDevices*: lent seq[PciIOProtocol] =
  if allDevices.isSome:
    return allDevices.get()
  return initAllDevices()
