    processor 6502
    include "vcs.h"
    include "macro.h"

NTSC = 0
PAL60 = 1

    IFNCONST SYSTEM
SYSTEM = NTSC
    ENDIF

; ----------------------------------
; constants

#if SYSTEM = NTSC
; NTSC Colors
SKY_YELLOW = $FA
#else
; PAL Colors
SKY_YELLOW = $2A
#endif

            SEG.U variables
            ORG $80

pattern ds 1


            SEG
            ORG $F000
Reset

    ; do the clean start macro
            CLEAN_START

            ldx #$28
            stx pattern

            lda #$01
            sta $01

StartOfFrame

  ; Start of vertical blank processing
            
            lda #0
            sta VBLANK
            sta COLUBK              ; background colour to black

    ; 3 scanlines of vertical sync signal to follow

            ldx #%00000010
            stx VSYNC               ; turn ON VSYNC bit 1

            sta WSYNC               ; wait a scanline
            sta WSYNC               ; another
            sta WSYNC               ; another = 3 lines total

            sta VSYNC               ; turn OFF VSYNC bit 1

    ; 37 scanlines of vertical blank to follow

;--------------------
; VBlank start

            lda #1
            sta VBLANK

            lda #42    ; vblank timer will land us ~ on scanline 34
            sta TIM64T

;---------------------
; meltfall

            stx #$ff
meltfall_loop
            lda $ff,x
            sta $00,x
            dex
            bne meltfall_loop

waitOnVBlank            
            cpx TIM64T
            bmi waitOnVBlank

            sta WSYNC
            ldx #$07
melt_resp_loop
            dex
            bpl melt_resp_loop
            sta RESP0
            lda #SKY_YELLOW
            sta COLUP0

melt_loop
            sta WSYNC

            lda #POND_WATER
            sta COLUBK

            ldy #16
            ldx #185
pondLoop    sta WSYNC
            lda FISH_0,y
            sta GRP0
            dey
            bpl pondLoop_cont
            ldy #16
pondLoop_cont  
            dex
            bne pondLoop

            ; overscan
            lda #0
            sta COLUBK
            ldx #30
overscan    sta WSYNC
            dex
            bne overscan  

            jmp StartOfFrame            

;-----------------------------------------------------------------------------------
; the CPU reset vectors

    ORG $F7FA

    .word Reset          ; NMI
    .word Reset          ; RESET
    .word Reset          ; IRQ

    END