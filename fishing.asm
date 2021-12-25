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
P0_COLOR   = $10
P1_COLOR   = $20
P2_COLOR   = $30
P3_COLOR   = $40
POND_WATER = $A0
#else
; PAL Colors
P0_COLOR   = $10
P1_COLOR   = $20
P2_COLOR   = $30
P3_COLOR   = $40
POND_WATER = $92
#endif

            SEG.U variables
            ORG $80

bobber_hpos ds 4
bobber_vpos ds 4
catch_count ds 4

;-------------
;.|        |.;
;-/        \-; 
;    G       ;
;-\     B  /-;
;.|        |.;
;-------------

            SEG
            ORG $F000
Reset

    ; clear cld
            cld

    ; set TIA to known state (clear to 0)

            lda #0
            ldx #$3f
.zapTIA     sta 0,x
            dex
            bpl .zapTIA

            ldx #127
.zapRAM     sta $80,x
            dex
            bpl .zapRAM


StartOfFrame
   ; Start of vertical blank processing
            
            lda #0
            sta VBLANK

    ; 3 scanlines of vertical sync signal to follow

            lda #%00000010
            sta VSYNC               ; turn ON VSYNC bit 1

            sta WSYNC               ; wait a scanline
            sta WSYNC               ; another
            sta WSYNC               ; another = 3 lines total

            lda #0
            sta VSYNC               ; turn OFF VSYNC bit 1
            
    ; 37 scanlines of vertical blank to follow

            lda #1
            sta VBLANK
            ldx #37
vBlank      sta WSYNC
            dex
            bne vBlank
            lda #0
            sta VBLANK

startPlayfield
            ; bkgnd
            lda #POND_WATER
            sta COLUBK

            ; P0-P1
            lda #P0_COLOR
            sta COLUP0
            lda #P1_COLOR
            sta COLUP1

            lda #$03
            sta CTRLPF
            lda #$ff
            sta PF0
            lda #$fc
            sta PF1
            ldx #48
upperLoop   sta WSYNC
            dex
            bne upperLoop

            ; pond
            lda #$00
            sta PF0
            sta PF1
            ldx #96
pondLoop    sta WSYNC
            dex
            bne pondLoop

           ; P2-P3
            lda #P2_COLOR
            sta COLUP0
            lda #P3_COLOR
            sta COLUP1

            lda #$ff
            sta PF0
            lda #$fc
            sta PF1
            ldx #48
lowerLoop   sta WSYNC
            dex
            bne lowerLoop

endPlayfield
            lda #$00
            sta PF0
            sta PF1

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