func unlclog(number: cdouble): cdouble {.importc: "log", header: "<math.h>".}
func unlclog10(number: cdouble): cdouble {.importc: "log10", header: "<math.h>".}
func unlcexp(number: cdouble): cdouble {.importc: "exp", header: "<math.h>".}
func unlclogf(number: cfloat): cfloat {.importc: "logf", header: "<math.h>".}
func unlcexpf(number: cfloat): cfloat {.importc: "expf", header: "<math.h>".}

func unlcpow(a: cdouble, b: cdouble): cdouble {.exportc: "pow".} =
  unlcexp(b * unlclog(a))

func unlcpowf(a: cfloat, b: cfloat): cfloat {.exportc: "powf".} =
  unlcexpf(b * unlclogf(a))
