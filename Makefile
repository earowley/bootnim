OVMF      = images/OVMF.fd
STUB      = stubs/app.nim
NIM_CACHE = build/c
ZIG_CACHE = .zig-cache
OUT_DIR   = build/bin
APP_ROOT  = src/main.nim


default: build

run:
	qemu-system-x86_64 -pflash $(OVMF) -hda fat:rw:$(OUT_DIR) -net none

build: $(APP_ROOT)
	nim cc $(STUB)

release: $(APP_ROOT)
	nim cc -d:release --lineTrace:off --assertions:off --debuginfo:off --opt:size $(STUB)

clean:
	rm -rf $(OUT_DIR)/*

cleanall: clean
	rm -rf $(NIM_CACHE)/*
	rm -rf $(ZIG_CACHE)/*
