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
POND_WATER = $A0
#else
; PAL Colors
SKY_YELLOW = $2A
POND_WATER = $92
#endif

            SEG.U variables
            ORG $80

move_timer  ds 1
move_speed  ds 1
left_hpos   ds 1
left_vpos   ds 1


            SEG
            ORG $F000
Reset

    ; do the clean start macro
            CLEAN_START

init_game
            ldx #$07
            stx left_hpos
            ldx #$06
            stx move_speed

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


advance_loops
            dec move_timer
            bpl advance_loops_end
            lda move_speed
            sta move_timer
            lda left_hpos
            clc
            adc #$f0
            sta left_hpos
            dec left_vpos

advance_loops_end

player_graphics
            lda #SKY_YELLOW
            sta COLUP0
            lda #$03
            sta NUSIZ0

waitOnVBlank            
            cpx TIM64T
            bmi waitOnVBlank

            sta WSYNC
            lda #POND_WATER
            sta COLUBK

            ldx #$04
top_resp_loop
            dex
            bpl top_resp_loop
            sta RESP0


            lda left_vpos
            ldx #16
topLoop_a   sta WSYNC
            clc
            adc #$ff
            and #$0f
            tay
            lda FISH_8,y
            sta GRP0
            tya
            dex
            bpl topLoop_a
            sta left_vpos


            lda #$10
            sta HMP0
            lda left_vpos
            ldx #16
topLoop_b   sta WSYNC
            sta HMOVE
            clc
            adc #$ff
            and #$0f
            tay
            lda FISH_8,y
            sta GRP0
            tya
            dex
            bpl topLoop_b
            sta left_vpos            

            sta WSYNC            ;3   0
            ldx #$03             ;2   2
swim_resp_loop
            dex                  ;2   4
            bpl swim_resp_loop 
            sta RESP0
            lda left_hpos
            sta HMP0

            sta WSYNC
            sta HMOVE

            ldy #15
            ldx #125
pondLoop    sta WSYNC           ;3   0
            lda FISH_0,y        ;4   4
            sta GRP0            ;3   7
            tya                 ;2   9
            clc                 ;2  11
            adc left_vpos       ;3  13
            and $0f             ;2  15
            tay                 ;2  17
            lda FISH_0,y        ;4  21
            sta GRP0
            lda FISH_2,y
            sta GRP0
            dey
            bpl pondLoop_end
            ldy #15
pondLoop_end
            dex
            bne pondLoop
            lda #0
            sta GRP0

            ldx #30
bottomLoop  sta WSYNC
            dex
            bpl bottomLoop

            ; overscan
            lda #0
            sta COLUBK
            ldx #30
overscan    sta WSYNC
            dex
            bne overscan  

            jmp StartOfFrame            


    ORG $FF00

FISH_0
				byte	$0,$0,$0,$0,$40,$40,$e6,$3f,$3f,$1f,$f,$f,$6,$0,$0,$0; 16
FISH_1
				byte	$0,$0,$0,$0,$0,$6,$8f,$bf,$7f,$bf,$8f,$6,$0,$0,$0,$0; 16
FISH_2
				byte	$0,$0,$0,$0,$6,$f,$f,$1f,$3f,$3f,$e6,$40,$40,$0,$0,$0; 16
FISH_3
				byte	$0,$0,$0,$0,$0,$0,$0,$0,$c0,$e1,$35,$1d,$3,$3,$f,$f; 16
FISH_4
				byte	$80,$0,$0,$40,$0,$20,$10,$10,$0,$9,$5,$5,$3,$3,$f,$f; 16
FISH_5
				byte	$10,$10,$10,$18,$8,$8,$8,$8,$8,$9,$5,$5,$3,$3,$f,$f; 16
FISH_6
				byte	$90,$d0,$20,$40,$60,$60,$60,$30,$30,$78,$3c,$3c,$3c,$3c,$18,$18; 16
FISH_7
				byte	$24,$34,$8,$10,$18,$18,$18,$18,$18,$3c,$3c,$3c,$3c,$3c,$18,$18; 16
FISH_8
				byte	$9,$d,$2,$4,$6,$6,$6,$c,$c,$1e,$3c,$3c,$3c,$3c,$18,$18; 16

;-----------------------------------------------------------------------------------
; the CPU reset vectors

    ORG $FFFA

    .word Reset          ; NMI
    .word Reset          ; RESET
    .word Reset          ; IRQ

    END