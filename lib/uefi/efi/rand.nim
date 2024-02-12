proc rdrand*: uint =
  asm """
    loop:
    rdrand %0
    jc out
    inc %1
    cmp $0x100000, %1
    jne loop
    out:
    : "=&r" (`result`)
    : "r" (0)
    : "cc"
  """
