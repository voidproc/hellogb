include "hardware.inc"


;-------------------------------------------------------------------------------
; Wait for VBlank (LY=144)
;-------------------------------------------------------------------------------

macro wait_vblank
.waitVBlank\@
    ldh a, [rLY]
    cp a, SCRN_Y
    jr nz, .waitVBlank\@
endm


;-------------------------------------------------------------------------------
; Interrupt (VBlank) $40
;-------------------------------------------------------------------------------

section "VBlank Int", rom0[$0040]
    push af
    push hl
    call FadeInBG
    ;call Scroll
    pop hl
    pop af
    reti


;-------------------------------------------------------------------------------
; Header $100
;-------------------------------------------------------------------------------

section "Header", rom0[$0100]
    ; Disable interrupts while setup phase
    di

    jp EntryPoint

    ; For cartridge header area (?)
    ds $150 - @, 0


;-------------------------------------------------------------------------------
; Entry point $200
;-------------------------------------------------------------------------------

section "Main", rom0[$0200]
EntryPoint:
    ; Reset registers
    xor a
    ldh [rIF], a
    ldh [rNR52], a
    ldh [rSTAT], a
    ldh [rSCY], a
    ldh [rSCX], a
    ldh [rLYC], a

    ; Initial scroll pos
    ld a, -4
    ldh [rSCY], a

    ; Initial palette
    ld a, %00000000
    ldh [rBGP], a

    ; Init vars
    ld a, 16
    ldh [FadeInDelay], a
    ld a, -1
    ldh [FadeInPaletteIndex], a

    ; Wait for VBlank
    wait_vblank

    ; Turn LCD off
    xor a
    ldh [rLCDC], a

    ; Copy font tiledata
    ld hl, $9000
    ld de, FontTiles
    ld bc, FontTilesEnd - FontTiles
.copyFont
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or a, c  ; (b|c)!=0
    jr nz, .copyFont

    ; Setup tilemap
    ld hl, $9903
    ld de, HelloText
.printHello
    ld a, [de]
    ld [hli], a
    inc de
    and a
    jr nz, .printHello

    ; Setup interrupts
    ld a, IEF_VBLANK
    ldh [rIE], a
    ei

    ; Turn LCD on
    ld a, %10000001
    ldh [rLCDC], a

.loop
    jr .loop


;-------------------------------------------------------------------------------
; BG Fade in
;-------------------------------------------------------------------------------

FadeInBG:
    ; Decrement delay counter to 0
    ld hl, FadeInDelay
    dec [hl]
    jr z, .updatePalette
    ret

.updatePalette
    ; Reset delay counter
    ld [hl], 16

    ; Increment palette index
    ldh a, [FadeInPaletteIndex]
    inc a
    cp a, 4
    jr z, .exitFadeIn
    ldh [FadeInPaletteIndex], a

    ; Get palette[index]
    ld hl, FadeInPalette
    add a, l
    ld l, a
    ld a, [hl]

    ; Set BGP
    ldh [rBGP], a

.exitFadeIn
    ret


;-------------------------------------------------------------------------------
; Scroll
;-------------------------------------------------------------------------------

Scroll:
    ld d, 6  ; delay counter
.delay
    dec d
    jr nz, .delay
    dec e
    ld a, e
    ldh [rSCX], a
    ret


;-------------------------------------------------------------------------------
; Font tiledata definition
;-------------------------------------------------------------------------------

section "Tiles", rom0
FontTiles:
include "font.s"
FontTilesEnd:


;-------------------------------------------------------------------------------
; Text
;-------------------------------------------------------------------------------

section "Text", rom0
HelloText:
    db "HELLO GAMEBOY!", 0


;-------------------------------------------------------------------------------
; BG Palette List (Fade in)
;-------------------------------------------------------------------------------

section "Palette", rom0
FadeInPalette:
    db %00000000, %01010100, %10100100, %11100100,


;-------------------------------------------------------------------------------
; Variables
;-------------------------------------------------------------------------------

section "Vars", hram
FadeInDelay: ds 1
FadeInPaletteIndex: ds 1
