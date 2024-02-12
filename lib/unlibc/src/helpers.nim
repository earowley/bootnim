type FloatComponents = object
  exponent, mantissa: int
  negative: bool

template `[]`[T](p: ptr T, idx: SomeInteger): T =
  when typeof(idx) is SomeUnsignedInt:
    cast[ptr T](cast[uint](p) + (typeof(idx))(sizeof(T)) * idx)[]
  else:
    cast[ptr T](cast[int](p) + (typeof(idx))(sizeof(T)) * idx)[]

template `[]=`[T](p: ptr T, idx: SomeInteger, value: T) =
  when typeof(idx) is SomeUnsignedInt:
    cast[ptr T](cast[uint](p) + (typeof(idx))(sizeof(T)) * idx)[] = value
  else:
    cast[ptr T](cast[int](p) + (typeof(idx))(sizeof(T)) * idx)[] = value

func reinterpret[T](t: typedesc, val: T): t =
  when sizeof(t) != sizeof(T):
    {.error: "Types must have the same size to reinterpret"}
  else:
    var v = val
    let dst = cast[ptr uint8](result.addr)
    let src = cast[ptr uint8](v.addr)

    for i in 0..<sizeof(T):
      dst[i] = src[i]      

func components(f: SomeFloat): FloatComponents =
  when sizeof(f) == 4:
    let i = uint32.reinterpret(f)
    let m = i and ((1 shl 23) - 1)
    let e = (i shr 23) and ((1 shl 8) - 1)
    let n = (i and (1 shl 31)) != 0
    FloatComponents(exponent: int(e), mantissa: int(m), negative: n)
  elif sizeof(f) == 8:
    let i = uint64.reinterpret(f)
    let m = i and ((1 shl 52) - 1)
    let e = (i shr 52) and ((1 shl 11) - 1)
    let n = (i and (uint64(1) shl 63)) != 0
    FloatComponents(exponent: int(e), mantissa: int(m), negative: n)
