include "hardware.inc"

SECTION "Header", ROM0[$100]

	jp EntryPoint

	ds $150 - @, 0 ; Make room for the header

;First pass code, NOT OPTIMISED
;TODO: Progress tracking, Profiling if it seems necessary

section "Seive", rom0

include "hex.inc"

EntryPoint::
    ; Shut down audio circuitry
	ld a, 0
	ld [rNR52], a
    ; Do not turn the LCD off outside of VBlank
.waitVBlank
	ld a, [rLY]
	cp 144
	jp c, .waitVBlank

	; Turn the LCD off
	ld a, 0
	ld [rLCDC], a
    ; Load Tiles into VRAM
    ld de, Tiles
    ld hl, $9000
    ld bc, HEX_LEN ;Same as TilesEnd-Tiles, I guess. Not sure if there's an advantage of one over the other.
.copyloop
    ld a, [de]
    inc de
    ld [hl+], a
    dec bc
	ld a, b
	or a, c
    jp nz, .copyloop
    ; Initialise Tilemap
    ld hl, $9800
    ld bc, $400
.initloop
    ld a, 16
    ld [hl+], a
    dec bc
    ld a, b
    or a, c
    jp nz, .initloop
    ; Draw some text to the screen
    def base equ $9800
    ld a, $B
    ld[base], a
    ld a, $A
    ld[base+1], a
    ld a, $D
    ld[base+2], a
    ; Turn the LCD on
	ld a, LCDCF_ON | LCDCF_BGON
	ld [rLCDC], a
	; During the first (blank) frame, initialize display registers
	ld a, %11100100
	ld [rBGP], a
.done
    jp .done

Tiles:
incbin "hex.bin"
TilesEnd: