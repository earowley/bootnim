OVMF     = images/OVMF.fd
STUB     = stubs/app.nim
NIMCACHE = build/c
UNLIBC   = lib/unlibc/include
APP      = app.efi
OUT      = build/bin
BIN      = $(OUT)/$(APP)
NIM_LIB  = $(shell nim --verbosity:0 --eval:"import std/os; echo getCurrentCompilerExe().parentDir.parentDir / \"lib\"")
CFLAGS   = -fno-stack-protector    \
           -ffreestanding          \
           -mno-stack-arg-probe
ZFLAGS   = -o $(BIN)               \
           -I $(NIM_LIB)           \
           -I $(UNLIBC)            \
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
	nim cc $(STUB)

clean:
	rm -f $(NIMCACHE)/*
	rm -f $(OUT)/*
