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
p0Counter       EQU     $8C
p1Counter       EQU     $8D


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

            LDA     #$ff
            STA     s1+1
            STA     s2+1
            STA     s3+1
            STA     s4+1
            STA     s5+1
            STA     s6+1
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
            lda #30             ;2 28
            sta COLUP0          ;2 30
            lda #178
            sta COLUP1          ;2 30

newFrame

  ; Start of vertical blank processing
            
            lda #0
            sta VBLANK

    ; 3 scanlines of vertical sync signal

            lda #%00000010
            sta VSYNC               ; turn ON VSYNC bit 1

            sta WSYNC               ; wait a scanline
            sta WSYNC               ; another
            sta WSYNC               ; another = 3 lines total

            lda #0
            sta VSYNC               ; turn OFF VSYNC bit 1

    ; 37 scanlines of vertical blank

            ldx #35
vBlank      sta WSYNC
            dex
            bne vBlank

locP0
            sta WSYNC           ;3   0
            SLEEP 25            ;25 25
            sta RESP0           ;3  28 should be pp 21, sc 30, cc 90
            SLEEP 25            ;25 25
            sta RESP1            

bkgnd
            sta WSYNC       ;3 0
            ldx #0          ;2 5
            stx COLUBK      ;3 8  ; put a colour in the background

            lda #23         ;2 10
            sta p0Counter   ;3 13
            lda #23         ;2 15
            sta p1Counter   ;3 19

    ; 192 scanlines of picture
            ldy p0Counter   ;3 22
doPlayer0  
            sta WSYNC       ;3  0
            sta HMOVE       ;3  3 ; process hmoves
            lda (s3),Y      ;5  8 ; p0 draw
            sta GRP0        ;3 11
            lda (s1),Y      ;5 16
            sta NUSIZ0      ;3 19

            ldy p1Counter   ;3 22
            lda (s3),Y      ;6 25 ; p1 draw
            sta GRP1        ;3 28
            lda (s1),Y      ;6 34
            sta NUSIZ1      ;3 37
            lda (s2),Y      ;5 42
            sta HMP1        ;3 45
            dec p1Counter   ;5 50

            ldy p0Counter   ;3 53
            lda (s2),Y      ;5 58
            sta HMP0        ;3 61

            dec p0Counter   ;5 66
            dey             ;2 68
            bne doPlayer0   ;2 70/71

            lda #0              ;2 17
            sta GRP0
            sta GRP1

            ldx #192 - 23          ;2 28
picture     sta WSYNC           ;3 3
            dex
            bne picture

overscan
            ldx #30
doOverscan  sta WSYNC               ; wait a scanline
            dex
            bne doOverscan

            jmp newFrame

;-----------------------------------------------------------------------------------

    ORG     $FF00

        byte	$0,$0,$0,$5,$5,$5,$5,$5,$5,$7,$7,$5,$5,$7,$5,$5,$5,$0,$0,$0,$0,$0,$0,$0; 24
        byte	$0,$0,$f0,$f0,$f0,$0,$0,$0,$0,$c0,$10,$40,$0,$10,$20,$20,$f0,$e0,$50,$10,$0,$10,$f0,$0; 24
        byte	$0,$cc,$c1,$8c,$ee,$c6,$ee,$fe,$fe,$f8,$f8,$ff,$ff,$f8,$ef,$ec,$e4,$cf,$f0,$e0,$f0,$c0,$90,$90; 24
        byte	$0,$7,$7,$7,$7,$5,$5,$5,$5,$7,$5,$5,$5,$5,$5,$5,$5,$5,$0,$0,$0,$0,$0,$0; 24
        byte	$0,$0,$10,$10,$0,$10,$0,$10,$10,$b0,$10,$20,$20,$10,$20,$20,$d0,$20,$30,$10,$0,$10,$f0,$0; 24
        byte	$0,$88,$88,$98,$d8,$e3,$ff,$ff,$fe,$f8,$ff,$ff,$ff,$ff,$ef,$ee,$b3,$e4,$f0,$e0,$f0,$c0,$90,$90; 24

;-----------------------------------------------------------------------------------
; the CPU reset vectors

    ORG $FFFA

    .word Reset          ; NMI
    .word Reset          ; RESET
    .word Reset          ; IRQ

    END