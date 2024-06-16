rom := seive.gb

RGBDS ?= C:/tools/msys64/usr/local/bin/
RGBASM  ?= $(RGBDS)rgbasm
RGBFIX  ?= $(RGBDS)rgbfix
RGBGFX  ?= $(RGBDS)rgbgfx
RGBLINK ?= $(RGBDS)rgblink

default: $(rom)

%.o: %.asm Makefile
	$(RGBASM) $(RGBASMFLAGS) -o $@ $<

opts = -jv -k 01 -l 0x33 -m 0x00 -p 0xff -t SEIVE

%.gb: %.o
	$(RGBLINK) -p 0xff -m $(rom:.gb=.map) -n $(rom:.gb=.sym) -o $@ $(filter %.o,$^)
	$(RGBFIX) $(opts) $@

%.bin %.inc: %.png
	python maketiles.py $^

screentest.asm : hex.bin hex.inc hardware.inc
seive.asm : hex.bin hex.inc hardware.inc

%.asm : hardware.inc