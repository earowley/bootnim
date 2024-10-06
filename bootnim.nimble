import std/strformat

author           = "Eric Rowley"
description      = "Nim environment for UEFI applications/drivers"
version          = "0.1.0"
license          = "MIT"
backend          = "c"
srcDir           = "stubs"
binDir           = "build/bin"
bin              = @["app"]
namedBin[bin[0]] = bin[0] & ".efi"

requires "nim >= 2.0.0"

task release, "Build an optimized binary":
  switch("d", "release")
  switch("lineTrace", "off")
  switch("assertions", "off")
  switch("debuginfo", "off")
  switch("opt", "size")
  setCommand("build")

before qemu:
  exec "nimble build"

task qemu, "Run the binary in QEMU":
  let ovmf = "images/OVMF.fd"
  exec fmt"qemu-system-x86_64 -pflash {ovmf} -hda fat:rw:{binDir} -net none"

task purge, "Clean all binary and cache directories":
  let ncache = "build/c/*"
  let bins = fmt"{binDir}/*"
  exec fmt"rm -rf {ncache} {bins}"
