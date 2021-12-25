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
POND_WATER = $A0
#else
; PAL Colors
POND_WATER = $92
#endif

            SEG.U variables
            ORG $80

frame ds 1
audspeed ds 1
audpat ds 1
mode  ds 1
audc  ds 1
audf  ds 1
buzzer ds 1

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

            lda #$13
            sta audf
            lda #$00
            sta audc
            lda #$02
            sta audspeed
            sta frame
            lda #$d8
            sta audpat
            sta mode

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
            ldx #36
vBlank      sta WSYNC
            dex
            bne vBlank
            lda #0
            sta VBLANK



movePlayer_dir
; SL 23
            sta WSYNC            ;3   0
            lda #$08
            sta AUDV1
            lda #$80
            bit SWCHA            ;3   3
            beq movePlayer_right ;2   5
            lsr                  ;2   7
            bit SWCHA            ;3  10
            beq movePlayer_left  ;2  12
            lda #$00
            sta AUDV1
            jmp movePlayer_end   ;3  30

movePlayer_right
            lda #$02
            sta AUDF1
            jmp movePlayer_end
movePlayer_left
            sec
            lda audspeed
            sbc frame
            sta AUDF1
            lda #$0a

movePlayer_end
            sta AUDC1

updateAudio
            sta WSYNC
            dec frame
            bpl updateAudio_end
            ror mode
            bcc updateAudio_clear
            lda audf
            sta AUDF0
            lda audc
            sta AUDC0
            lda #$03
            sta AUDV0
            jmp updateAudio_reset
updateAudio_clear
            bne updateAudio_clear_0
            lda audpat
            sta mode
updateAudio_clear_0
            lda #$00
            sta AUDF0
            sta AUDC0
            sta AUDV0
updateAudio_reset
            lda audspeed
            sta frame
updateAudio_end


startPlayfield

; 44 22      *   *   *   *   *
; ee 77     *** *** *** *** ***
;          ********************
;          45677654321001234567

; c0 c0 0f   ****      ****    
; f0 f3 3f ********  ******** 
; ff ff ff ********************
;          45677654321001234567

            ; parallax
            sta WSYNC
            lda #POND_WATER
            sta COLUBK
            sta WSYNC
            lda #$22
            sta PF1
            asl
            sta PF2
            sta WSYNC
            lda #$22
            sta PF1
            asl
            sta PF0
            sta PF2
            sta WSYNC
            lda #$77
            sta PF1
            asl
            sta PF0
            sta PF2
            sta WSYNC
            lda #$77
            sta PF1
            asl
            sta PF0
            sta PF2
            sta WSYNC
            lda #$ff
            sta PF1
            sta PF0
            sta PF2
            sta WSYNC

            ; pond
            sta WSYNC
            lda #POND_WATER
            sta COLUBK
            lda #$00
            sta PF1
            sta PF0
            sta PF2
            ldx #185
pondLoop    sta WSYNC
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