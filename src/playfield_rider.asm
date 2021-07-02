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

  ; black playfield sidebars
            lda #$30
            sta PF0
            lda #$01
            sta CTRLPF

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
            ldx #35
vBlank      sta WSYNC
            dex
            bne vBlank

    ; 192 scanlines of picture to follow


; ----------------------------------
; horizon kernel
; SL -2
            sta WSYNC
            SLEEP 40
            sta RESP0
            sta RESP1
            lda #0
            sta HMP0
            lda #$10
            sta HMP1
            lda #1
            sta NUSIZ0
; SL -1
            sta WSYNC                ;3   0
            sta HMOVE                ;3   3
            lda #SUN_RED             ;2   5
            sta COLUP0               ;3   8
            sta COLUP1               ;3  11

; SL 0 ... 36
; 36 variable width bands of color gradient 

            ldy #13                  ;2  13
            ldx #35                  ;2  15
horizonLoop
            sta WSYNC                ;3   0 
            lda HORIZON_COLOR,y      ;4   4 
            sta COLUBK               ;3   7
            lda SUN_SPRITE_LEFT,x    ;4  11 
            sta GRP0                 ;3  14
            lda SUN_SPRITE_MIDDLE,x  ;4  18  
            sta GRP1                 ;3  21
            lda #0                   ;2  23
            sta REFP0                ;1  24
            SLEEP 16                 ;13 39
            lda #8                   ;2  39
            sta REFP0                ;3  42

            dex                      ;2  44
            bmi horizonEnd           ;2  47
            txa                      ;2  49
            cmp HORIZON_COUNT,y      ;4  53
            bpl horizonLoop          ;2* 55
            dey                      ;2  57
            jmp horizonLoop          ;2* 59
horizonEnd

            lda #0                   ;
            sta GRP0                 ;
            sta GRP1                 ;
            sta REFP1                ;
            sta NUSIZ0               ;

; ----------------------------------
; playfield kernel 

    ; SC 36           

            sta WSYNC
            lda #GREEN
            sta COLUBK

            lda #8
rail_A  
            sta WSYNC
            dex
            bne rail_A

            jsr rider_A
            jsr rider_A
            jsr rider_A
            jsr rider_A      
            jsr rider_A      

    ; SC 180
            lda #BLACK
            sta COLUBK
            ldx #12
logo 
            sta WSYNC
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
; Rider A Pattern

rider_A    
            sta WSYNC       ;3  0 
            SLEEP 50        ;25 25
            sta RESP1       ;3  56      
            ldy #23         ;2  63
rider_A_loop  
            sta WSYNC         ;3  0
            sta HMOVE         ;3  3 ; process hmoves
            lda (graphics0),y ;6 25 ; p1 draw
            sta GRP1          ;3 28
            lda (scale0),y    ;6 34
            sta NUSIZ1        ;3 37
            lda (tessfo0),y   ;5 42
            sta HMP1          ;3 45
            dey 
            bne rider_A_loop  ;2 70/71

            lda #0              ;2 17
            sta GRP1


;-----------------------------------------------------------------------------------
; the graphics

    ORG $FF00
HORIZON_COLOR ; 14 bytes
        byte CLOUD_ORANGE - 2, CLOUD_ORANGE, CLOUD_ORANGE + 2, CLOUD_ORANGE + 4, 250, 252, 254, 252, 250, WHITE_WATER, SKY_BLUE + 8, SKY_BLUE + 4, SKY_BLUE + 2, SKY_BLUE 
HORIZON_COUNT ; 14 bytes
        byte $0, $2, $4, $6, $7, $8, $b, $13, $16, $17, $18, $1a, $1c, $1f 
SUN_SPRITE_LEFT ; 36
        byte $ff,$ff,$ff,$ff,$7f,$7f,$7f,$7f,$3f,$3f,$3f,$1f,$1f,$f,$f,$7,$3,$1,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
SUN_SPRITE_MIDDLE ; 36
        byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$3c,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
RIDER_0_NUSIZ
        byte	$0,$0,$0,$5,$5,$5,$5,$5,$5,$7,$7,$5,$5,$7,$5,$5,$5,$0,$0,$0,$0,$0,$0,$0; 24
RIDER_0_HMOV
        byte	$0,$0,$f0,$f0,$f0,$0,$0,$0,$0,$c0,$10,$40,$0,$10,$20,$20,$f0,$e0,$50,$10,$0,$10,$f0,$0; 24
RIDER_0_IMOV
        byte	$0,$cc,$c1,$8c,$ee,$c6,$ee,$fe,$fe,$f8,$f8,$ff,$ff,$f8,$ef,$ec,$e4,$cf,$f0,$e0,$f0,$c0,$90,$90; 24
RIDER_0_GRAPHICS
        byte	$0,$e0,$f0,$f0,$0,$0,$0,$f0,$0,$f0,$f0,$f0,$0,$d0,$0,$0,$10,$20,$50,$0,$f0,$10,$f0,$0; 24

;-----------------------------------------------------------------------------------
; the CPU reset vectors

    ORG $FFFA

    .word Reset          ; NMI
    .word Reset          ; RESET
    .word Reset          ; IRQ

    END