import
  ../common
export
  common

type
  InputReset = proc(self: SimpleTextInputProtocol, extendedVerification: bool): EfiStatus {.cdecl.}
  InputReadKey = proc(self: SimpleTextInputProtocol, key: ptr InputKey): EfiStatus {.cdecl.}

  InputKey {.bycopy.} = object
    scanCode, unicodeChar: uint16

  SimpleTextInputProtocolObj {.byCopy.} = object
    reset: InputReset
    readKeyStroke: InputReadKey
    waitForKey: EfiEvent
  SimpleTextInputProtocol* = ptr SimpleTextInputProtocolObj

proc reset*(self: SimpleTextInputProtocol) =
  discard self.reset(self, false)

proc readKey*(self: SimpleTextInputProtocol): uint16 =
  var key: InputKey
  discard self.readKeyStroke(self, key.addr)
  result = key.unicodeChar

proc waitForKeyEvent*(self: SimpleTextInputProtocol): EfiEvent =
  self.waitForKey
