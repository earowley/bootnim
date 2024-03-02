OVMF     = images/OVMF.fd
STUB     = stubs/app.nim
NIMCACHE = build/c
UNLIBC   = lib/unlibc/src
UNLIBCH  = lib/unlibc/include
UEFI     = lib/uefi
SRC      = src
APP      = app.efi
OUT      = build/bin
BIN      = $(OUT)/$(APP)
NIM_LIB  = $(shell nim --verbosity:0 --eval:"import std/os; echo getCurrentCompilerExe().parentDir.parentDir / \"lib\"")
NIMFLAGS = -d:useMalloc            \
           -d:noSignalHandler      \
           --path:$(UNLIBC)        \
           --path:$(UEFI)          \
           --path:$(SRC)           \
           --mm:arc                \
           --os:any                \
           --cpu:amd64             \
           --compileOnly           \
           --nimcache:$(NIMCACHE)  \
           --threads:off
CFLAGS   = -fno-stack-protector    \
           -ffreestanding          \
           -mno-stack-arg-probe
ZFLAGS   = -o $(BIN)               \
           -I $(NIM_LIB)           \
           -I $(UNLIBCH)           \
           --target=x86_64-uefi    \
           $(CFLAGS)
NIM_SRC  = src/main.nim


default: zigcc

qemu: zigcc
	qemu-system-x86_64 -pflash $(OVMF) -hda fat:rw:$(OUT) -net none

zigcc: $(BIN)

$(BIN): nimcc
	zig cc $(ZFLAGS) $(NIMCACHE)/*.nim.c

nimcc: $(NIM_SRC)
	nim cc $(NIMFLAGS) $(STUB)

clean:
	rm -f $(NIMCACHE)/*
	rm -f $(OUT)/*
