func unlclog(number: cdouble): cdouble {.importc: "log", header: "<math.h>", cdecl.}
func unlclog10(number: cdouble): cdouble {.importc: "log10", header: "<math.h>", cdecl.}
func unlcexp(number: cdouble): cdouble {.importc: "exp", header: "<math.h>", cdecl.}
func unlclogf(number: cfloat): cfloat {.importc: "logf", header: "<math.h>", cdecl.}
func unlcexpf(number: cfloat): cfloat {.importc: "expf", header: "<math.h>", cdecl.}

func unlcpow(a: cdouble, b: cdouble): cdouble {.exportc: "pow", cdecl.} =
  unlcexp(b * unlclog(a))

func unlcpowf(a: cfloat, b: cfloat): cfloat {.exportc: "powf", cdecl.} =
  unlcexpf(b * unlclogf(a))
