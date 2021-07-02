; Kernel #1 - pretty rainbow

    processor 6502
    include "vcs.h"
    include "macro.h"


    SEG.U variables
    ORG $80

   ; TODO - variablize
s1              EQU     $80
s2              EQU     $82
s3              EQU     $84
s4              EQU     $86
s5              EQU     $88
s6              EQU     $8A
s7              EQU     $8C
LoopCount       EQU     $8E
Temp            EQU     $8F

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

initSprite
            LDA     #$01
            STA     VDELP0
            STA     VDELP1
            LDA     #$ff
            STA     s1+1
            STA     s2+1
            STA     s3+1
            STA     s4+1
            STA     s5+1
            STA     s6+1
            STA     s7+1
            LDA     #0
            STA     s1
            LDA     #24
            STA     s2
            LDA     #48
            STA     s3
            LDA     #72
            STA     s4
            LDA     #96
            STA     s5
            LDA     #120
            STA     s6
            LDA     #144
            STA     s7
            LDA     #$03
            STA     NUSIZ0
            STA     NUSIZ1

newFrame

  ; Start of vertical blank processing
            
            lda #0
            sta VBLANK

            sta COLUBK              ; background colour to black

    ; 3 scanlines of vertical sync signal

            lda #%00000010
            sta VSYNC               ; turn ON VSYNC bit 1

            sta WSYNC               ; wait a scanline
            sta WSYNC               ; another
            sta WSYNC               ; another = 3 lines total

            lda #0
            sta VSYNC               ; turn OFF VSYNC bit 1


    ; 37 scanlines of vertical blank

            ldx #37
vBlank      sta WSYNC
            dex
            bne vBlank

    ; sprite positioning
sPos
            sta WSYNC
            nop                 ;2 2
            nop                 ;2 4
            nop                 ;2 6
            nop                 ;2 8
            nop                 ;2 10
            nop                 ;2 12
            nop                 ;2 14
            nop                 ;2 16
            nop                 ;2 18
            nop                 ;2 20
            sta RESP0           ;3 23 pos 6
            sta RESP1           ;3 26
            lda #35             ;2 28
            sta COLUP0          ;2 30
            sta COLUP1          ;2 32

            ldx #0              ;2 34
            stx COLUBK          ;3 37  ; put a colour in the background

            lda #23             ;2 39
            sta LoopCount       ;3 42

doSprites:
            nop                 ;2 44 
            nop                 ;2 46 
            nop                 ;2 48
            nop                 ;2 50
            nop                 ;2 52
            nop                 ;2 54

loopSprites:         
            ldy     LoopCount   ;3 58 3
            lda     (s1),Y      ;5 63 8
            sta     GRP0        ;3 66 11
            lda     (s2),Y      ;5 71 16
            sta     GRP1        ;3 74 19
            lda     (s3),Y      ;5 3  22
            sta     GRP0        ;3 6  28
            lda     (s6),Y      ;5 11 33
            sta     Temp        ;3 14 36
            lda     (s5),Y      ;5 19 41
            tax                 ;2 21 43
            lda     (s4),Y      ;5 26 48
            ldy     Temp        ;3 29 51
            sta     GRP1        ;3 32 54
            stx     GRP0        ;3 35 57
            sty     GRP1        ;3 38 60
            sta     GRP0        ;3 41 63
            nop                 ;2 43 65
            nop                 ;2 45 67
            nop                 ;2 47 69
            dec     LoopCount   ;5 52 74
            bpl     loopSprites ;3 55* 77*
            lda     #0
            sta     GRP0
            sta     GRP1
            jmp newFrame

            ldx #0
doOverscan  sta WSYNC               ; wait a scanline
            inx
            cpx #30
            bne doOverscan


            jmp newFrame

;-----------------------------------------------------------------------------------
; the Sprite data

    ORG     $FF00

    byte	$0,$1,$2,$4,$b,$e,$f,$1f,$1f,$1f,$3f,$7f,$df,$87,$1,$0,$1,$2,$1,$2,$4,$8,$0,$0; 24
    byte	$0,$0,$46,$81,$3,$6,$7e,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$f3,$fd,$f0,$f8,$3c,$1c,$1e,$c,$12,$12; 24
    byte	$0,$0,$80,$40,$21,$62,$c4,$88,$10,$a0,$c0,$b0,$c8,$e6,$fe,$fc,$f8,$70,$20,$0,$0,$0,$0,$0; 24
    byte	$0,$84,$48,$28,$34,$1e,$1f,$f,$1f,$1f,$7f,$ff,$9f,$f,$1,$0,$2,$1,$1,$2,$4,$8,$0,$0; 24
    byte	$0,$0,$0,$0,$0,$1,$3d,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$f3,$fc,$f0,$f8,$3c,$1c,$1e,$c,$12,$12; 24
    byte	$0,$20,$48,$48,$91,$92,$24,$e8,$d0,$a0,$c0,$c0,$fc,$e3,$ff,$fe,$7c,$38,$10,$0,$0,$0,$0,$0; 24
    byte	$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0; 24

;-----------------------------------------------------------------------------------
; the CPU reset vectors

    ORG $FFFA

    .word Reset          ; NMI
    .word Reset          ; RESET
    .word Reset          ; IRQ

    END