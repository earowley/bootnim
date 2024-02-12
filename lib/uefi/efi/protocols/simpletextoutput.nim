import ../common

type
  TextReset = proc (this: ptr SimpleTextOutputProtocolImpl, extendedVerification: bool): EfiStatus {.cdecl.}
  TextString = proc (this: ptr SimpleTextOutputProtocolImpl, str: ptr uint16): EfiStatus {.cdecl.}
  TextTestString = proc (this: ptr SimpleTextOutputProtocolImpl, str: ptr uint16): EfiStatus {.cdecl.}
  TextQueryMode = proc (this: ptr SimpleTextOutputProtocolImpl, modeNumber: uint, columns, rows: ptr uint): EfiStatus {.cdecl.}
  TextSetMode = proc(this: ptr SimpleTextOutputProtocolImpl, modeNumber: uint): EfiStatus {.cdecl.}
  TextSetAttribute = proc(this: ptr SimpleTextOutputProtocolImpl, attribute: uint): EfiStatus {.cdecl.}
  TextClearScreen = proc(this: ptr SimpleTextOutputProtocolImpl): EfiStatus {.cdecl.}
  TextSetCursorPosition = proc(this: ptr SimpleTextOutputProtocolImpl, column, row: uint): EfiStatus {.cdecl.}
  TextEnableCursor = proc(this: ptr SimpleTextOutputProtocolImpl, visible: bool): EfiStatus {.cdecl.}

  SimpleTextOutputMode* {.byCopy.} = object
    maxMode*: int32
    mode*: int32
    attribute*: int32
    cursorColumn*: int32
    cursorRow*: int32
    cursorVisible*: bool

  SimpleTextOutputProtocolImpl {.byCopy.} = object
    reset: TextReset
    outputString: TextString
    testString: TextTestString
    queryMode: TextQueryMode
    setMode: TextSetMode
    setAttribute: TextSetAttribute
    clearScreen: TextClearScreen
    setCursorPosition: TextSetCursorPosition
    enableCursor: TextEnableCursor
    mode: ptr SimpleTextOutputMode

  SimpleTextOutputProtocol* = ptr SimpleTextOutputProtocolImpl

proc reset*(self: SimpleTextOutputProtocol) =
  discard self.reset(self, false)

proc clear*(self: SimpleTextOutputProtocol) =
  discard self.clearScreen(self)

proc mode*(self: SimpleTextOutputProtocol): SimpleTextOutputMode =
  self.mode[]

proc writeString*(self: SimpleTextOutputProtocol, data: openArray[uint16]) =
  discard self.outputString(self, data[0].unsafeAddr)

proc writeString*(self: SimpleTextOutputProtocol, data: ptr UncheckedArray[uint16]) =
  discard self.outputString(self, data[0].unsafeAddr)
