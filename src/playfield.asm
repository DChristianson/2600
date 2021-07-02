    processor 6502
    include "vcs.h"
    include "macro.h"

SKY_BLUE = 160
DARK_WATER = 160
SUN_RED = 48
CLOUD_ORANGE = 34
GREY_SCALE = 2 
WHITE_WATER = 10
GREEN = 178
RED = 66
YELLOW = 30
WHITE = 14
BLACK = 0

    SEG
    ORG $F000

Reset

    ; set TIA to known state (clear to 0)

            lda #0
            ldx #0
.zapTIA     sta 0,x
            inx
            cpx #$40
            bne .zapTIA


newFrame

  ; Start of vertical blank processing
            
            lda #0
            sta VBLANK

            sta COLUBK              ; background colour to black

    ; 3 scanlines of vertical sync signal to follow

            lda #%00000010
            sta VSYNC               ; turn ON VSYNC bit 1

            sta WSYNC               ; wait a scanline
            sta WSYNC               ; another
            sta WSYNC               ; another = 3 lines total

            lda #0
            sta VSYNC               ; turn OFF VSYNC bit 1

    ; 37 scanlines of vertical blank to follow
            ldx #37
vBlank      sta WSYNC
            dex
            bne vBlank

    ; 192 scanlines of picture to follow
    ; SC 0
            lda #SKY_BLUE
            sta COLUBK
            REPEAT 8
                sta WSYNC
            REPEND

    ; SC 8
            lda #SKY_BLUE + 2
            sta COLUBK
            REPEAT 4
                sta WSYNC
            REPEND

    ; SC 12
            lda #SKY_BLUE + 4
            sta COLUBK
            REPEAT 2
                sta WSYNC
            REPEND

    ; SC 14
            lda #SKY_BLUE + 8
            sta COLUBK
            REPEAT 2
                sta WSYNC
            REPEND

    ; SC 15
            lda #WHITE_WATER
            sta COLUBK
            REPEAT 1
                sta WSYNC
            REPEND

    ; SC 16
            lda #250
            sta COLUBK
            sta WSYNC
            SLEEP 40
            sta RESP0 ; pp 66
            sta RESP1 ; pp 75
            lda #SUN_RED
            sta COLUP0
            sta COLUP1
            lda #$81
            sta GRP0
            sta GRP1
            sta REFP1
            lda #$10
            sta HMP0
            sta HMP1

            sta WSYNC
    ; SC 18
            lda #252
            sta COLUBK
            REPEAT 4
                sta WSYNC
            REPEND

    ; SC 22
            lda #254
            sta COLUBK
            REPEAT 8
                sta WSYNC
            REPEND

    ; SC 30
            lda #252
            sta COLUBK
            REPEAT 2
                sta WSYNC
            REPEND

    ; SC 32
            lda #CLOUD_ORANGE
            sta COLUBK
            REPEAT 2
                sta WSYNC
            REPEND

    ; SC 34
            lda #CLOUD_ORANGE + 2
            sta COLUBK
            REPEAT 2
                sta WSYNC
            REPEND

    ; SC 36           
            lda #GREEN
            sta COLUBK
            ldx #130
playfield0   sta WSYNC
            dex
            bne playfield0
            sta WSYNC
            SLEEP 70
            sta HMOVE
            sta WSYNC
            ldx #12
playfield1   sta WSYNC
            dex
            bne playfield1

    ; SC 180
            lda #BLACK
            sta COLUBK
            ldx #12
logo sta WSYNC
            dex
            bne logo

            lda #0
            sta COLUBK              ; background colour to black

    ; SC 192
    ; 30 lines of overscan to follow

            ldx #00
doOverscan  sta WSYNC               ; wait a scanline
            inx
            cpx #30
            bne doOverscan


            jmp newFrame
;-----------------------------------------------------------------------------------
; the graphics

    ORG $FF00

        byte	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f,$7f,$7f,$7f,$7f,$3f,$3f,$3f,$1f,$1f,$f,$f,$7,$3,$1,$0,$0; 24
        byte	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$3c; 24
        byte	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$fe,$fc,$fc,$fc,$f8,$f8,$f0,$f0,$e0,$c0,$80,$0,$0; 24

;-----------------------------------------------------------------------------------
; the CPU reset vectors

    ORG $FFFA

    .word Reset          ; NMI
    .word Reset          ; RESET
    .word Reset          ; IRQ

    END