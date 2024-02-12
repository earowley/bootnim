import std/math as stdmath

func ln(f: float32): float32 =
  when nimvm:
    stdmath.ln(f)
  else:
    unlclogf(cfloat(f))

func ln(f: float64): float64 =
  when nimvm:
    stdmath.ln(f)
  else:
    unlclog(cdouble(f))

func log[F: float32 | float64](a, b: F): F =
  ln(a) / ln(b)  

func log10(f: float64): float64 =
  unlclog10(f)

func pow(a, b: float32): float32 =
  unlcpowf(cfloat(a), cfloat(b))

func pow(a, b: float64): float64 =
  unlcpow(cdouble(a), cdouble(b))
