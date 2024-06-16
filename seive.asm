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

    ld hl, $9800
    ld bc, $400
    ;initialise Tilemap to 0
.initloop
    ld a, 16
    ld [hl+], a
    dec bc
	ld a, b
	or a, c
    jp nz, .initloop

	; During the first (blank) frame, initialize display registers
	ld a, %11100100
	ld [rBGP], a

    ;initialise RAM
    ld hl, $C000
    ld bc, $2000
.ramloop
    ld a, 0
    ld [hl+], a
    dec bc
	ld a, b
	or a, c
    jp nz, .ramloop

    ; Compute prime into ahl
    call Seive

    ; Write prime on screen
    ld [$9800], a
    ld a, h
    srl a
    srl a
    srl a
    srl a
    ld [$9801], a
    ld a, h
    and %1111
    ld [$9802], a
    ld a, l
    srl a
    srl a
    srl a
    srl a
    ld [$9803], a
    ld a, l
    and %1111
    ld [$9804], a

    ; Turn the LCD on
	ld a, LCDCF_ON | LCDCF_BGON
	ld [rLCDC], a
.done
    jp .done


Tiles:
incbin "hex.bin"
TilesEnd:

;Note: Can do bitcheck faster using align[8], but is a little ugly. I settled for the code shown here.

macro BitCheck ; Note that this assembles to 8 bytes.
    pop hl
    bit \1, [hl]
    jp .endbitcheck
    nop
    nop
endm

macro ZeroCount
.zerocount\1
    bit \1, [hl]
    jp nz, \2
    inc bc
endm

macro CountBack
.cb\1
    ld d, \1
    bit \1, [hl]
    jp nz, \2
    dec a
    jp z, .endcountback
endm

def PRIME equ 10001

;Returns prime in ahl, treated as a 24-bit register
Seive::
    ld c, 1 ;3 = 2*1+1 is the first prime we want to seive
.primeloop
    call SeivePrime
    ;Find the next prime to seive with
.increment
    inc c
    ld a, c
    cp a, 181
    jp z, .exitloop ;exits after 363=2*181+1, the first odd number greater than sqrt(2*66536-1)
    and %111
    ;Compute 8*a, so that we can jump to the code that checks the correct bit later
    add a
    add a
    add a
    ld l, c
    srl l
    srl l
    srl l
    ld h, $C0
    push hl ; Stashing the address of the byte so it can be used by the bitcheck later
    ld hl, .bitcheck
    ld e, a
    ld d, 0
    add hl, de
    jp hl ; Jump to .bitcheck + 8 * bit index
.bitcheck ; Each of these macro sections are 8 bytes long, allowing us to jump directly to the code that checks the correct bit
    BitCheck 0
    BitCheck 1
    BitCheck 2
    BitCheck 3
    BitCheck 4
    BitCheck 5
    BitCheck 6
    BitCheck 7
.endbitcheck
    ;If the bit is a 1, i.e. nz, then the number has been seived and is composite
    jp nz, .increment
    jp .primeloop

    ;Now that seiving is complete, we need to count primes
.exitloop
    ld bc, 0
    ld hl, _RAM
.countloop
    ZeroCount 0, .zerocount1
    ZeroCount 1, .zerocount2
    ZeroCount 2, .zerocount3
    ZeroCount 3, .zerocount4
    ZeroCount 4, .zerocount5
    ZeroCount 5, .zerocount6
    ZeroCount 6, .zerocount7
    ZeroCount 7, .endcount
.endcount
    inc hl
    ;Note that since 1 is counted, but 2 is skipped, the value of bc we want is 10001. That's why check here for 10000-bc < 0
    ld a, high(PRIME-1)
    cp b
    jp nz, .countloop
    ld a, low(PRIME-1)
    cp c
    jp nc, .countloop
    ;We may have overcounted, so we need to count backwards to get the exact value of the prime
    dec hl
    ld a, c
    sub a, low(PRIME-1) ;You might be worried about overflows here, but it just works.
    CountBack 7, .cb6
    CountBack 6, .cb5
    CountBack 5, .cb4
    CountBack 4, .cb3
    CountBack 3, .cb2
    CountBack 2, .cb1
    CountBack 1, .cb0
    CountBack 0, .endcountback
.endcountback
    sla l
    rl h
    sla l
    rl h
    sla l
    rl h
    ld a, l
    or a, d
    ld l, a
    ld a, 0
    sla l
    rl h
    rl a
    inc hl
    ;Now ahl is a (big-endian) 24 bit int storing the value of the prime
    ret

macro BitSet ; Note that this assembles to 8 bytes.
    pop hl
    set \1, [hl]
    jp .endbitset
    nop
    nop
endm

;Given an odd prime 2*c+1, it sieves out all of the multiples of 2*b+1 from the range 
SeivePrime::
    ld hl, 0
    ld l, c
    ld b, 0
.loop
    ;Adding 2*bc+1 to hl
    add hl, bc
    add hl, bc
    inc hl
    ;Return if hl is large enough. Doesn't quite utilise all of ram. I'm not sure how much further I can push it, and I can't be bothered figuring it out.
    ld a, $F7
    cp a, h
    ret c
    push hl
    ld a, l
    and a, %111 ;bit index
    ld d, a
    sla d ;bit index multiplied by 8
    sla d
    sla d
    ;Next, we shift hl down by three bits to get the address
    ;In subsequent versions I may have hl be pre-shifted
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l
    ld a, h
    or $C0 ;This puts us in the right area of ram
    ld h, a
    push hl
    ld hl, .bitset
    ld a, l
    add a, d
    ld l, a
    jp hl
.bitset
    BitSet 0
    BitSet 1
    BitSet 2
    BitSet 3
    BitSet 4
    BitSet 5
    BitSet 6
    BitSet 7
.endbitset
    pop hl
    jp .loop