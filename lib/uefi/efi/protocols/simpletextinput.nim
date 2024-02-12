import ../common

type
  InputReset = proc(this: ptr SimpleTextInputProtocolImpl, extendedVerification: bool): EfiStatus {.cdecl.}
  InputReadKey = proc(this: ptr SimpleTextInputProtocolImpl, key: ptr InputKey): EfiStatus {.cdecl.}

  InputKey {.byCopy.} = object
    scanCode, unicodeChar: uint16

  SimpleTextInputProtocolImpl {.byCopy.} = object
    reset: InputReset
    readKeyStroke: InputReadKey
    waitForKey: EfiEvent

  SimpleTextInputProtocol* = ptr SimpleTextInputProtocolImpl

proc reset*(self: SimpleTextInputProtocol) =
  discard self.reset(self, false)

proc readKey*(self: SimpleTextInputProtocol): uint16 =
  var key: InputKey
  discard self.readKeyStroke(self, key.addr)
  result = key.unicodeChar

proc waitForKey*(self: SimpleTextInputProtocol): EfiEvent =
  self.waitForKey
