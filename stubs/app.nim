include unlibc
from main import main

# Needed to make the linker happy
let fltused {.exportc: "_fltused".}: int = 0

# Since we're defining our own entry point, we must call main ourselves.
# Not to be confused with the application code main function.
proc cMain(argc: cint, argv, env: ptr ptr cchar): cint {.importc: "main", cdecl.}


proc EfiMain*(imageHandle: EfiHandle, systemTable: SystemTable): EfiStatus {.exportc, cdecl.} =
  # Setup anything libc needs to run
  gSystemTable = systemTable
  gHandle = imageHandle
  unlcstdin = stdinImpl.unsafeAddr
  unlcstdout = stdoutImpl.unsafeAddr
  unlcstderr = stderrImpl.unsafeAddr
  result = Success
  discard cMain(0, nil, nil)


when isMainModule:
  {.push warning[BareExcept]: off.}
  try:
    main()
  except Exception as e:
    for tmp in getStackTraceEntries(e):
      echo tmp.filename, "(", tmp.line, ") ", tmp.procname
    echo "Error: unhandled exception: ", e.msg, " [", e.name, "]"
  {.pop.}
