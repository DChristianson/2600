    processor 6502
    include "vcs.h"
    include "macro.h"

; ----------------------------------
; constants

SKY_BLUE = 160
SKY_YELLOW = 250
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

; ----------------------------------
; variables

  SEG.U variables

    ORG $80

rider_ctrl      ds 2
rider_graphics  ds 2
rider_color     ds 5
rider_hdelay    ds 5
rider_hmov      ds 5
rider_index     ds 1
player_ctrl     ds 2
player_graphics ds 2
player_color    ds 1
player_index    ds 1
player_vdelay   ds 1
delay           ds 1
timer           ds 1


    SEG

; ----------------------------------
; code

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

  ; rider positions
            lda #$fe
            sta player_ctrl+1
            sta player_graphics+1
            lda #$ff
            sta rider_ctrl+1
            sta rider_graphics+1

            lda #<PLAYER_SPRITE_0_CTRL
            sta player_ctrl
            lda #<PLAYER_SPRITE_0_GRAPHICS
            sta player_graphics
            lda #BLACK
            sta player_color

            lda #<RIDER_SPRITE_0_CTRL
            sta rider_ctrl
            lda #<RIDER_SPRITE_0_GRAPHICS
            sta rider_graphics
            lda #RED
            sta rider_color
            lda #WHITE
            sta rider_color + 1
            lda #YELLOW
            sta rider_color + 2
            lda #RED
            sta rider_color + 3
            lda #YELLOW
            sta rider_color + 4
            ldx #10
            stx rider_hdelay
            stx rider_hdelay + 1
            stx rider_hdelay + 2
            stx rider_hdelay + 3
            stx rider_hdelay + 4
            ldx #2
            stx timer
            lda #0
            sta player_vdelay
        

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
            ldx #34
vBlank      sta WSYNC
            dex
            bne vBlank

            sta WSYNC
            ldx timer
            dex
            bpl skipUpdate
            lda player_ctrl
            cmp #<PLAYER_SPRITE_2_CTRL
            bne skipCtrl0
            lda #<PLAYER_SPRITE_0_CTRL
            jmp savCtrl0
skipCtrl0
            adc #48
savCtrl0
            sta player_ctrl
            lda player_graphics
            cmp #<PLAYER_SPRITE_2_GRAPHICS
            bne skipGraphics0
            lda #<PLAYER_SPRITE_0_GRAPHICS
            jmp savGraphics0
skipGraphics0
            adc #48
savGraphics0
            sta player_graphics
            ldx player_vdelay
            inx
            cpx #120
            bmi skipLimit
            ldx #50
skipLimit   
            stx player_vdelay
            ldx #2
skipUpdate
            stx timer
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
            sta NUSIZ1
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
            sta REFP0                ;
            sta NUSIZ0               ;
            sta NUSIZ1               ;

; ----------------------------------
; playfield kernel 

    ; SC 36           

            sta WSYNC
            lda #GREEN
            sta COLUBK
            SLEEP 21
            sta RESP0
            lda player_color
            sta COLUP0
            lda player_vdelay
            sta player_index

            ldx #8
rail_A  
            sta WSYNC
            dex
            bne rail_A
;
           ldx #0
           jsr rider_move_end
           jsr rider_A ;37
           ldx #1
           jsr rider_move_end
           jsr rider_A ;37
           ldx #2
           jsr rider_move_end
           jsr rider_A ;37
           ldx #3
           jsr rider_move_end
           jsr rider_A ;37  
           ldx #4
           jsr rider_A ;37     

            ldx #8
rail_B  
            sta WSYNC
            dex
            bne rail_B

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
            ; locate p1
            sta WSYNC               ;3   0 
            sta HMOVE               ;3   3 ; process hmoves

            ldy player_index        ;3   6
            cpy #24                 ;2   8
            bpl skip_p0             ;2  10 
            lda (player_graphics),y ;5  15 ; p0 draw
            sta GRP0                ;3  18
            lda (player_ctrl),y     ;6  22
            sta NUSIZ0              ;3  25
            sta HMP0                ;3  28
            jmp loc_p1              ;3  31
skip_p0    ;11
           SLEEP 20
loc_p1
            lda rider_hdelay,x      ;4  35
            sta delay               ;3  38
            ;jmp (delay)            ;5  43
        ;     byte      $c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9
        ;     byte      $c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9
        ;     byte      $c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9
        ;     byte      $c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c5
            sta RESP1               ;3  46
            lda rider_hmov,x        ;2  47
            sta HMP1                ;3  50
            lda rider_color,x       ;4  54
            sta COLUP1              ;3  57
            lda #23                 ;2  59
            sta rider_index         ;3  62
            dec player_index        ;5  67
            bpl rider_A_loop        ;2  69
            lda #$7f                ;2  71
            sta player_index        ;3  74 

rider_A_loop  
            sta WSYNC               ;3   0
            sta HMOVE               ;3   3 ; process hmoves

            ldy player_index        ;3   6
            cpy #24                 ;2   8
            bpl draw_p1             ;2  10 
            lda (player_graphics),y ;5  15 ; p0 draw
            sta GRP0                ;3  18
            lda (player_ctrl),y     ;6  22
            sta NUSIZ0              ;3  25
            sta HMP0                ;3  28

draw_p1
            ldy rider_index
            lda (rider_graphics),y  ;5   8 ; p1 draw
            sta GRP1                ;3  11
            lda (rider_ctrl),y      ;6  16
            sta NUSIZ1              ;3  19
            sta HMP1                ;3  27
            dec player_index
            bpl rider_A_loop_d1     ;2  69
            lda #$7f                ;2  71
            sta player_index        ;3  74 
rider_A_loop_d1
            dec rider_index 
            bne rider_A_loop        ;2 26

            sta WSYNC               ;3   0
            sta HMOVE               ;3   3 ; process hmoves

            ldy player_index        ;3   6
            cpy #24                 ;2   8
            bpl end_p1              ;2  10 
            lda (player_graphics),y ;5  15 ; p0 draw
            sta GRP0                ;3  18
            lda (player_ctrl),y     ;6  22
            sta NUSIZ0              ;3  25
            sta HMP0                ;3  28
end_p1
            lda #0                  ;2  2
            sta GRP0                ;3  5
            sta GRP1                ;3  5
            dec player_index
            bpl rider_A_loop_d2     ;2  69
            lda #$7f                ;2  71
            sta player_index        ;3  74 
rider_A_loop_d2
            rts                     ;6 11

;-----------------------------------------------------------------------------------
; rider movement

rider_move
            lda rider_hmov,x
            sbc #$10
            bvc rider_move_end
            lda #$7f
            dec rider_hdelay,x
            bpl rider_move_end
            ldy #20
            sty rider_hdelay,x
rider_move_end
            sta rider_hmov,x
            rts
;-----------------------------------------------------------------------------------
; sprite graphics
    ORG $FE00

PLAYER_SPRITE_0_CTRL
    byte $0,$5,$15,$15,$5,$f5,$f5,$5,$5,$f7,$35,$c7,$55,$d7,$65,$5,$f5,$5,$50,$10,$0,$0,$0,$0; 24
PLAYER_SPRITE_0_GRAPHICS
    byte $0,$96,$a6,$c6,$4e,$62,$77,$7f,$7f,$f8,$ff,$f8,$ff,$fc,$ef,$77,$73,$b2,$f0,$e0,$f0,$60,$90,$90; 24
PLAYER_SPRITE_1_CTRL
    byte $0,$0,$5,$f5,$5,$15,$f5,$5,$5,$5,$d7,$f7,$17,$47,$35,$5,$f5,$20,$30,$10,$0,$0,$0,$0; 24
PLAYER_SPRITE_1_GRAPHICS
    byte $0,$66,$af,$a7,$c2,$c4,$e6,$fe,$ff,$ff,$f8,$7c,$fc,$f8,$ef,$77,$b2,$fc,$f0,$e0,$f0,$60,$90,$90; 24
PLAYER_SPRITE_2_CTRL
    byte $0,$5,$f5,$5,$f5,$5,$f5,$5,$5,$f7,$35,$c7,$55,$d7,$65,$5,$f5,$5,$40,$20,$0,$0,$0,$0; 24
PLAYER_SPRITE_2_GRAPHICS
    byte $0,$2a,$26,$76,$66,$66,$73,$7f,$7f,$f8,$ff,$f8,$ff,$fc,$ef,$77,$73,$b2,$78,$f0,$60,$90,$90,$0; 24

    ORG $FF00

RIDER_SPRITE_0_CTRL
    byte $0,$5,$f5,$f5,$f5,$f5,$5,$f5,$5,$17,$f5,$7,$f5,$d7,$5,$5,$15,$5,$30,$30,$0,$0,$0,$0; 24
RIDER_SPRITE_0_GRAPHICS
    byte $0,$b6,$9e,$8e,$e4,$46,$6f,$7f,$7f,$f8,$ff,$f8,$ff,$fc,$f7,$ee,$ce,$4d,$f,$70,$f0,$60,$90,$90; 24
RIDER_SPRITE_1_CTRL
    byte $0,$0,$a5,$15,$15,$15,$f5,$5,$f5,$f5,$c7,$f7,$17,$7,$5,$15,$25,$40,$0,$0,$0,$0,$0,$0; 24
RIDER_SPRITE_1_GRAPHICS
    byte $0,$33,$af,$cf,$86,$8c,$ce,$fe,$ff,$ff,$7c,$7c,$fc,$f8,$f7,$de,$9a,$3f,$78,$70,$f0,$60,$90,$90; 24
RIDER_SPRITE_2_CTRL
    byte $0,$5,$15,$15,$f5,$f5,$f5,$5,$5,$17,$f5,$7,$f5,$d7,$5,$5,$15,$25,$10,$30,$0,$0,$0,$0; 24
RIDER_SPRITE_2_GRAPHICS
    byte $0,$a8,$c8,$9c,$46,$66,$67,$7f,$7f,$f8,$ff,$f8,$ff,$fc,$f7,$ee,$ce,$9a,$f,$f0,$60,$90,$90,$0; 24

HORIZON_COLOR ; 14 bytes
        byte CLOUD_ORANGE - 2, CLOUD_ORANGE, CLOUD_ORANGE + 2, CLOUD_ORANGE + 4, 250, 252, 254, 252, 250, WHITE_WATER, SKY_BLUE + 8, SKY_BLUE + 4, SKY_BLUE + 2, SKY_BLUE 
HORIZON_COUNT ; 14 bytes
        byte $0, $2, $4, $6, $7, $8, $b, $13, $16, $17, $18, $1a, $1c, $1f 
SUN_SPRITE_LEFT ; 36
        byte $ff,$ff,$ff,$ff,$7f,$7f,$7f,$7f,$3f,$3f,$3f,$1f,$1f,$f,$f,$7,$3,$1,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
SUN_SPRITE_MIDDLE ; 36
        byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$3c,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
    
;-----------------------------------------------------------------------------------
; the CPU reset vectors

    ORG $FFFA

    .word Reset          ; NMI
    .word Reset          ; RESET
    .word Reset          ; IRQ

    END