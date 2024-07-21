import
  ../common

type
  RuntimeServicesTableObj {.byCopy.} = object
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
  RuntimeServicesTable* = ptr RuntimeServicesTableObj
