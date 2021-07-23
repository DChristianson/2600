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
RIDER_HEIGHT = 24
NUM_RIDERS = 5
PLAYER_SPEED = 2
RIDER_SPEED = 1
RIDER_RESP_START = 9

; ----------------------------------
; variables

  SEG.U variables

    ORG $80

rider_ctrl      ds 2
rider_graphics  ds 2
rider_color     ds 5
rider_hdelay    ds 5
rider_hmov_0    ds 5
rider_hmov_1    ds 5
rider_index     ds 1
player_ctrl     ds 2
player_graphics ds 2
player_color    ds 1
player_index    ds 1
player_vdelay   ds 1
player_vpos     ds 1
delay           ds 1
player_timer    ds 1
rider_timer     ds 5


    SEG

; ----------------------------------
; code

  SEG
    ORG $F000

Reset
    ; clear cld
            cld

    ; set TIA to known state (clear to 0)

            lda #0
            ldx #0
.zapTIA     sta 0,x
            inx
            cpx #$40
            bne .zapTIA

  ; black playfield sidebars, on top of players
            lda #$30
            sta PF0
            lda #$05
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
            ldx #RIDER_RESP_START
            stx rider_hdelay
            dex
            stx rider_hdelay + 1
            dex
            stx rider_hdelay + 2
            dex
            stx rider_hdelay + 3
            dex
            stx rider_hdelay + 4
            ldx #$90
            stx rider_hmov_0
            stx rider_hmov_0 + 1
            stx rider_hmov_0 + 2
            stx rider_hmov_0 + 3
            stx rider_hmov_0 + 4
            stx rider_hmov_1
            stx rider_hmov_1 + 1
            stx rider_hmov_1 + 2
            stx rider_hmov_1 + 3
            stx rider_hmov_1 + 4
            ldx #PLAYER_SPEED
            stx player_timer
            ldx #RIDER_SPEED
            stx rider_timer
            stx rider_timer + 1
            stx rider_timer + 2
            stx rider_timer + 3
            stx rider_timer + 4
            lda #0
            sta player_vpos
        

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
            ldx #37 - NUM_RIDERS - 3
vBlank      sta WSYNC
            dex
            bne vBlank
; SL -8
updatePlayer
            sta WSYNC
            ldx player_timer
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
            ldx player_vpos
            inx
            cpx #120
            bmi skipLimit
            ldx #1
skipLimit   
            ;stx player_vpos
            ldx #PLAYER_SPEED
skipUpdate
            stx player_timer

            ldx #NUM_RIDERS - 1
; SL -7 : -3
moveRider.loop
            sta WSYNC
            dec rider_timer,x   ;6   6
            bpl moveRider.end   ;2   8
            ldy #RIDER_SPEED    ;2  10
            sty rider_timer,x   ;4  14
            lda #$10            ;2  16
            clc                 ;2  18
            adc rider_hmov_0,x    ;4  22
            bvs moveRider.hmov2 ;2  24
            sta rider_hmov_0,x    ;4  28  
            jmp moveRider.end   ;3  31
moveRider.hmov2 ; push the second move register forward
            lda #$90                      ;2  27       
            cmp rider_hmov_1,x ;4  31 
            bne moveRider.resp            ;2  33
            sta rider_hmov_0,x              ;4  37
            lda #$70                      ;2  39
            sta rider_hmov_1,x ;4  43
            jmp moveRider.end             ;3  46
moveRider.resp            
            sta rider_hmov_1,x ;4  39
            dec rider_hdelay,x            ;7  46
            bpl moveRider.end             ;2  48
            lda #RIDER_RESP_START         ;2  50
            sta rider_hdelay,x            ;4  54
moveRider.end
            dex                           ;2  56
            bpl moveRider.loop            ;2  58
;A Y0 SC 29 PP  33
;A Y1 SC?34 PP? 48
;A Y2 SC 39 PP  63
;A Y3 SC 44 PP  78
;A Y4 SC 49 PP  93
;A Y5 SC 54 PP 108
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
            sta HMCLR
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
            lda player_vpos
            sta player_vdelay
            lda #RIDER_HEIGHT - 1
            sta player_index

            ldx #8
rail_A.loop 
            sta WSYNC
            dex
            bne rail_A.loop

riders_start
            ldx #4
            jmp rider_A.start

riders_end

            ldx #8
rail_B.loop  
            sta WSYNC
            dex
            bne rail_B.loop

    ; SC 180
            lda #BLACK
            sta COLUBK
            ldx #12
logo.loop 
            sta WSYNC
            dex
            bne logo.loop

            lda #0
            sta COLUBK              ; background colour to black

    ; SC 192
    ; 30 lines of overscan to follow

            ldx #00
doOverscan  sta WSYNC               ; wait a scanline
            inx
            cpx #30
            bne doOverscan
            lda #$01
            bit SWCHB
            bne doOverscan.end
            jmp Reset

doOverscan.end
            jmp newFrame

;-----------------------------------------------------------------------------------
; Rider A Pattern
; rider only, waiting for player

rider_A.start
            ; locate p1
            sta WSYNC               ;3   0 
            lda rider_hmov_0,x        ;4   4
            sta HMP1                ;3   7
            ldy rider_hdelay,x      ;4  11
            iny                     ;2  13

rider_A.resp; strobe resp 
            dey                     ;2  15
            bne rider_A.resp        ;2+ 17 
            sta RESP1               ;3  20 (17 + hdelay * 5)
            dec player_vdelay       ;5  25
            beq rider_B.hmov        ;2  27

rider_A.hmov; locating rider horizontally 2
            sta WSYNC                     ;3   0 
            sta HMOVE                     ;3   3 ; process hmoves
            lda rider_color,x             ;4   7
            sta COLUP1                    ;3  10
            lda #RIDER_HEIGHT - 1         ;2  12
            sta rider_index               ;3  15
            lda rider_hmov_1,x ;4  19
            sta HMP1                      ;3  28
            dec player_vdelay             ;5  33
            beq rider_B.loop              ;2  35

rider_A.loop;
            sta WSYNC               ;3   0
            sta HMOVE               ;3   3 ; process hmoves

            ldy rider_index
            lda (rider_graphics),y  ;5   8 ; p1 draw
            sta GRP1                ;3  11
            lda (rider_ctrl),y      ;5  16
            sta NUSIZ1              ;3  19
            sta HMP1                ;3  22
            dec player_vdelay       ;5  27
            beq rider_B.loop.a      ;2  29
rider_A.loop.a;
            dec rider_index         ;5  34
            bpl rider_A.loop        ;2  36

rider_A.end
            sta WSYNC               ;3  36

            dec player_vdelay       ;5  41
            beq rider_B.end.a       ;2  43

rider_A.end.a
            dex                     ;2  45
            bpl rider_A.start       ;2  47
            jmp riders_end          ;3  50

;-----------------------------------------------------------------------------------
; Rider B Pattern 
; player + rider on same line

rider_B.start
            ; locate p1
            sta WSYNC               ;3   0 
            sta HMOVE               ;3   3 ; process hmoves

            ldy player_index        ;3   6
            lda (player_graphics),y ;5  11 ; p0 draw
            sta GRP0                ;3  14
            lda (player_ctrl),y     ;5  19
            sta NUSIZ0              ;3  22
            sta HMP0                ;3  25

            ldy rider_hdelay,x      ;5  30
rider_B.resp
            dey                     ;3  33
            bne rider_B.resp      ;2  35 + hdelay * 6
            sta RESP1               ;3  38
            lda rider_hmov_0,x        ;2  40
            sta HMP1                ;3  43
            lda rider_color,x       ;4  47
            sta COLUP1              ;3  50
            lda #RIDER_HEIGHT - 1   ;2  52
            sta rider_index         ;3  55
            dec player_index        ;5  60
            bmi rider_A.hmov        ;2  62

rider_B.hmov; locating rider horizontally
            sta WSYNC               ;3   0 
            sta HMOVE               ;3   3 ; process hmoves

            ldy player_index        ;3   6
            lda (player_graphics),y ;5  11 ; p0 draw
            sta GRP0                ;3  14
            lda (player_ctrl),y     ;5  19
            sta NUSIZ0              ;3  22
            sta HMP0                ;3  25

            lda rider_hmov_1,x ;2  22
            sta HMP1                      ;3  25
            dec player_vdelay       ;5  56
            beq rider_A.loop        ;2  58

rider_B.loop  
            sta WSYNC               ;3   0
            sta HMOVE               ;3   3 ; process hmoves

            ldy player_index        ;3   6
            lda (player_graphics),y ;5  11 ; p0 draw
            sta GRP0                ;3  14
            lda (player_ctrl),y     ;5  19
            sta NUSIZ0              ;3  22
            sta HMP0                ;3  25

            ldy rider_index         ;3  28
            lda (rider_graphics),y  ;5  33 ; p1 draw
            sta GRP1                ;3  36
            lda (rider_ctrl),y      ;5  41
            sta NUSIZ1              ;3  44
            sta HMP1                ;3  47
            dec player_index        ;5  52
            bmi rider_A.loop.a      ;2  54

rider_B.loop.a
            dec rider_index 
            bpl rider_B.loop        ;2 26

rider_B.end
            sta WSYNC               ;3   0
            sta HMOVE               ;3   3 ; process hmoves

            ldy player_index        ;3   6
            lda (player_graphics),y ;5  15 ; p0 draw
            sta GRP0                ;3  18
            lda (player_ctrl),y     ;6  22
            sta NUSIZ0              ;3  25
            sta HMP0                ;3  28

            dec player_index
            bmi rider_A.end.a       ;2  69

rider_B.end.a
            dex                    ;6 11
            bpl rider_B.start
            jmp riders_end

;-----------------------------------------------------------------------------------
; rider movement

; rider_move
;             lda rider_hmov_0,x
;             sbc #$10
;             bvc rider_move_end
;             lda #$7f
;             dec rider_hdelay,x
;             bpl rider_move_end
;             ldy #20
;             sty rider_hdelay,x
; rider_move_end
;             sta rider_hmov_0,x
;             rts

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