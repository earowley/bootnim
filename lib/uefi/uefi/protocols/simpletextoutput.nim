import
  ../common

type
  TextReset = proc (self: SimpleTextOutputProtocol, extendedVerification: bool): EfiStatus {.cdecl.}
  TextString = proc (self: SimpleTextOutputProtocol, str: ptr uint16): EfiStatus {.cdecl.}
  TextTestString = proc (self: SimpleTextOutputProtocol, str: ptr uint16): EfiStatus {.cdecl.}
  TextQueryMode = proc (self: SimpleTextOutputProtocol, modeNumber: uint, columns, rows: ptr uint): EfiStatus {.cdecl.}
  TextSetMode = proc(self: SimpleTextOutputProtocol, modeNumber: uint): EfiStatus {.cdecl.}
  TextSetAttribute = proc(self: SimpleTextOutputProtocol, attribute: uint): EfiStatus {.cdecl.}
  TextClearScreen = proc(self: SimpleTextOutputProtocol): EfiStatus {.cdecl.}
  TextSetCursorPosition = proc(self: SimpleTextOutputProtocol, column, row: uint): EfiStatus {.cdecl.}
  TextEnableCursor = proc(self: SimpleTextOutputProtocol, visible: bool): EfiStatus {.cdecl.}

  SimpleTextOutputMode* = object
    maxMode*: int32
    mode*: int32
    attribute*: int32
    cursorColumn*: int32
    cursorRow*: int32
    cursorVisible*: bool

  SimpleTextOutputProtocolObj {.byCopy.} = object
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
  SimpleTextOutputProtocol* = ptr SimpleTextOutputProtocolObj

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
