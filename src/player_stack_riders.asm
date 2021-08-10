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
RIDER_RESP_START = 8

; ----------------------------------
; variables

  SEG.U variables

    ORG $80

rider_animate   ds 1
rider_ctrl      ds 2
rider_graphics  ds 2
rider_color     ds 5
rider_hdelay    ds 5
rider_hmov_0    ds 5
rider_hmov_1    ds 5
rider_timer     ds 5
rider_hit       ds 1
player_animate  ds 1
player_ctrl     ds 2
player_graphics ds 2
player_color    ds 1
player_vdelay   ds 1
player_vpos     ds 1
player_hmov     ds 1
player_charge   ds 1
player_fire     ds 1
player_hit      ds 1
tmp             ds 1

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
            lda #>PLAYER_SPRITE_START
            sta player_ctrl+1
            sta player_graphics+1
            lda #>RIDER_SPRITE_START
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
            ldx #$80
            stx rider_hmov_0
            stx rider_hmov_0 + 1
            stx rider_hmov_0 + 2
            stx rider_hmov_0 + 3
            stx rider_hmov_0 + 4
            ldx #$0
            stx rider_hit
            stx player_charge
            stx player_hit
            stx player_hmov
            stx rider_hmov_1
            stx rider_hmov_1 + 1
            stx rider_hmov_1 + 2
            stx rider_hmov_1 + 3
            stx rider_hmov_1 + 4
            ldx #PLAYER_SPEED
            stx player_animate
            ldx #RIDER_SPEED
            stx rider_animate
            stx rider_timer
            stx rider_timer + 1
            stx rider_timer + 2
            stx rider_timer + 3
            stx rider_timer + 4
            lda #$01
            sta player_vpos

newFrame

  ; Start of vertical blank processing
            
            lda #0
            sta VBLANK
            sta COLUBK              ; background colour to black
            sta COLUPF

    ; 3 scanlines of vertical sync signal to follow

            lda #%00000010
            sta VSYNC               ; turn ON VSYNC bit 1

            sta WSYNC               ; wait a scanline
            sta WSYNC               ; another
            sta WSYNC               ; another = 3 lines total

            lda #0
            sta VSYNC               ; turn OFF VSYNC bit 1

    ; 37 scanlines of vertical blank to follow
            ldx #37 - NUM_RIDERS - 6 - 10
vBlank      sta WSYNC
            dex
            bne vBlank

; SL -21
            sta WSYNC
            lda player_hit
            sta COLUPF

; SL -20
animatePlayer
            sta WSYNC
            dec player_animate
            bpl animatePlayer_end
            lda player_ctrl
            cmp #<PLAYER_SPRITE_2_CTRL
            bne animatePlayer_skipCtrl0
            lda #<PLAYER_SPRITE_0_CTRL
            jmp animatePlayer_savCtrl0
animatePlayer_skipCtrl0
            clc
            adc #48
animatePlayer_savCtrl0
            sta player_ctrl
            lda player_graphics
            cmp #<PLAYER_SPRITE_2_GRAPHICS
            bne animatePlayer_skipGraphics0
            lda #<PLAYER_SPRITE_0_GRAPHICS
            jmp animatePlayer_savGraphics0
animatePlayer_skipGraphics0
            clc
            adc #48
animatePlayer_savGraphics0
            sta player_graphics
            ldx #PLAYER_SPEED
            stx player_animate
animatePlayer_end

; SL -19 : -11
; we're going to copy the current graphics to the stack
            ldy #$0    
stackPlayer_loop
            cpy #RIDER_HEIGHT
            bpl stackPlayer_loop_end
            php
            lda (player_ctrl),y  
            pha
            lda (player_graphics),y  
            pha
            iny
            jmp stackPlayer_loop
stackPlayer_loop_end

; SL -10
movePlayer
            sta WSYNC                ;3   0
            lda #$80                 ;3   3
            bit INPT4                ;3   6
            bne movePlayer_button_up ;2   8
            inc player_charge        ;5  13
            jmp movePlayer_dir       ;3  16
movePlayer_button_up
            ldx player_charge    ;3  12
            stx player_fire      ;3  15
            ldx #0               ;2  17
            ;stx player_charge    ;3  20 BUGBUG debugging

; SL -9
movePlayer_dir
            sta WSYNC            ;3   0
            bit SWCHA            ;3   3
            beq movePlayer_right ;2   5
            lsr                  ;2   7
            bit SWCHA            ;3  10
            beq movePlayer_left  ;2  12
            lsr                  ;2  14
            bit SWCHA            ;3  17
            beq movePlayer_down  ;2  19
            lsr                  ;3  22
            bit SWCHA            ;3  25
            beq movePlayer_up    ;2  27
            jmp movePlayer_end   ;3  30

movePlayer_right
            lda #$F0             ;2   8
            jmp movePlayer_horiz ;3  11
movePlayer_left
            lda #$10             ;2  15
movePlayer_horiz
            clc                  ;2  17
            adc player_hmov      ;3  20
            bvs movePlayer_end   ;2  22
            sta player_hmov      ;3  25
            jmp movePlayer_end   ;3  28
movePlayer_down
            inc player_vpos      ;5  42
            lda #110             ;2  44
            cmp player_vpos      ;3  47
            bmi movePlayer_up    ;2  49
            jmp movePlayer_end   ;3  52
movePlayer_up
            dec player_vpos      ;5  33
            beq movePlayer_down  ;3  36
            
movePlayer_end

; SL -8
animateRider
            sta WSYNC
            dec rider_animate
            bpl animateRider_end
            lda rider_ctrl
            cmp #<RIDER_SPRITE_2_CTRL
            bne animateRider_skipCtrl0
            lda #<PLAYER_SPRITE_0_CTRL
            jmp animateRider_savCtrl0
animateRider_skipCtrl0
            clc
            adc #48
animateRider_savCtrl0
            sta rider_ctrl
            lda rider_graphics
            cmp #<RIDER_SPRITE_2_GRAPHICS
            bne animateRider_skipGraphics0
            lda #<RIDER_SPRITE_0_GRAPHICS
            jmp animateRider_savGraphics0
animateRider_skipGraphics0
            clc
            adc #48
animateRider_savGraphics0
            sta rider_graphics
            ldx #RIDER_SPEED
            stx rider_animate
animateRider_end

            ldx #NUM_RIDERS - 1
; SL -7 : -3
moveRider_loop
            sta WSYNC
            dec rider_timer,x   ;6   6
            bpl moveRider_end   ;2   8
            ldy #RIDER_SPEED    ;2  10
            sty rider_timer,x   ;4  14
            lda #$10            ;2  16
            clc                 ;2  18
            adc rider_hmov_0,x  ;4  22
            bvs moveRider_resp  ;2  24
            sta rider_hmov_0,x  ;4  28  
            jmp moveRider_end   ;3  31
moveRider_resp
            lda #$90              ;2  27
            sta rider_hmov_0,x    ;4  31  
            dec rider_hdelay,x    ;6  37
            bpl moveRider_end     ;2  39
            lda #RIDER_RESP_START ;2  41
            sta rider_hdelay,x    ;4  45
moveRider_end
            dex                   ;2  47
            bpl moveRider_loop    ;2  49

;A Y0 SC 22 PP  12
;A Y1 SC 27 PP  27
;A Y2 SC 32 PP  42
;A Y3 SC 37 PP  57
;A Y4 SC 42 PP  72
;A Y5 SC 47 PP  87
;A Y6 SC 52 PP 102
;A Y7 SC 57 PP 117
;A Y8 SC 62 PP 132
;A Y9 SC 67 PP 147

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

            lda #0                   ;2  50
            sta GRP0                 ;3  53
            sta GRP1                 ;3  56
            sta REFP0                ;3  59
            sta NUSIZ0               ;3  62
            sta NUSIZ1               ;3  65
            sta HMCLR                ;3  68

; ----------------------------------
; playfield kernel 

    ; SC 36           

            sta WSYNC                ;3   0
            lda #GREEN               ;2   2
            sta COLUBK               ;3   5
            ldy #4                   ;2   7
player_resp_loop
            dey                      ;2   9
            bpl player_resp_loop     ;2  11 + 20 = 31
            sta RESP0                ;3  34
            lda player_color         ;3  37
            sta COLUP0               ;3  40
            lda player_vpos          ;3  43 
            sta player_vdelay        ;3  46

    ; SC  37
            sta WSYNC                ;3   0
            lda player_hmov          ;3   3
            ldy #4                   ;2   5
yari_resp_loop
            dey                      ;2   7
            bpl yari_resp_loop       ;2  9 + 20 = 29
            sta RESBL                ;3  32
            sta HMP0                 ;3  35
            sta HMBL                 ;3  38

    ; SC 38
            sta WSYNC                ;3   0
            sta HMOVE                ;3   3
            ldx #8                   ;2  10
rail_A_loop 
            sta WSYNC                ;3   0
            dex                      ;2   2
            bne rail_A_loop          ;2   4

riders_start
            stx HMP0                 ;3   7
            stx HMBL                 ;3  10
            sta CXCLR                ;3  13
            ldx #4                   ;2  15
            jmp rider_A_start        ;3  17

riders_end
            ldx #8
rail_B_loop  
            sta WSYNC
            dex
            bne rail_B_loop

    ; SC 180
            lda #BLACK
            sta COLUBK
            ldx #12
logo_loop 
            sta WSYNC
            dex
            bne logo_loop

            lda #0
            sta COLUBK              ; background colour to black


            lda CXPPMM 
            cmp #$80
            bmi player_miss
            inc player_hit
            
player_miss
            lda CXP1FB
            cmp #$40
            bne yari_miss
            inc rider_hit

yari_miss


    ; SC 192
    ; 30 lines of overscan to follow            

            ldx #30
doOverscan  sta WSYNC               ; wait a scanline
            dex
            bne doOverscan
            lda #$01
            bit SWCHB
            bne doOverscan_end
            jmp Reset

doOverscan_end
            jmp newFrame

;-----------------------------------------------------------------------------------
; Rider A Pattern
; rider only, waiting for player

rider_A_to_B_hmov
            lda #$ff
            sta ENABL
            sta HMBL
            jmp rider_B_hmov

rider_A_to_B_loop
            lda #$ff
            sta ENABL
            sta HMBL
            jmp rider_B_loop

rider_A_to_B_loop_a
            lda #$ff
            sta ENABL
            sta HMBL
            jmp rider_B_loop_a

rider_A_to_B_end_a
            lda #$ff                ;2  12
            sta ENABL               ;3  15
            sta HMBL                ;3  18
            jmp rider_B_end_a       ;3  21

rider_A_start_l
            dec player_vdelay        ;5  21
            beq rider_A_to_B_start_l ;2  23
            sta HMP1                 ;3  26
            dey                      ;2  28
            dey                      ;2  30
rider_A_resp_l; strobe resp
            dey                      ;2  32
            bne rider_A_resp_l       ;2+ 64 (34 + 6 * 5)
            SLEEP 3                  ;3  67 timing shim
            sta RESP1                ;3  70 
            jmp rider_A_hmov            

rider_A_to_B_start_l
            sta HMP1                ;3  27
            lda #$ff                ;2  29
            sta ENABL               ;3  32
            sta HMBL                ;3  35
            dey                     ;2  37
            dey                     ;2  39
            dey                     ;2  41
            dey                     ;2  43
rider_A_to_B_resp_l; strobe resp
            dey                     ;2  45
            bne rider_A_to_B_resp_l ;2+ 47 (47 + 3 * 5)
            sta RESP1               ;3  25+ 
            jmp rider_B_hmov

rider_A_start
            ; locate p1
            sta WSYNC               ;3   0 
            sta HMOVE               ;3   3
            lda rider_hmov_0,x      ;4   7
            ldy rider_hdelay,x      ;4  11
            cpy #$06                ;2  13
            bpl rider_A_start_l     ;2  15
            jmp rider_A_resp        ;3  18 noop

rider_A_resp; strobe resp 
            dey                     ;2  20
            bpl rider_A_resp        ;2+ 22 (22 + hdelay * 5)
            sta RESP1               ;3  25+ 
            sta HMP1                ;3  28
            dec player_vdelay       ;5  33
            beq rider_A_to_B_hmov   ;2  35

rider_A_hmov; locating rider horizontally 2
            sta WSYNC                     ;3   0 
            sta HMOVE                     ;3   3 ; process hmoves
rider_A_hmov_0; from rider B
            lda rider_color,x             ;4   7
            sta COLUP1                    ;3  10
            lda rider_hmov_1,x            ;4  14
            ldy #RIDER_HEIGHT - 1         ;2  16
            dec player_vdelay             ;5  21
            SLEEP 3
            sta HMP1                      ;3  27
            beq rider_A_to_B_loop         ;2  29

rider_A_loop;
            sta WSYNC               ;3   0
            sta HMOVE               ;3   3 ; process hmoves
rider_A_loop_body:
            lda (rider_graphics),y  ;5   8 ; p1 draw
            sta GRP1                ;3  11
            lda (rider_ctrl),y      ;5  16
            sta NUSIZ1              ;3  19
            dec player_vdelay       ;5  24
            sta HMP1                ;3  27
            beq rider_A_to_B_loop_a ;2  29
rider_A_loop_a;
            dey                     ;5  34 73
            bpl rider_A_loop        ;2  36 75

rider_A_end
            sta WSYNC               ;3  0
            sta HMOVE               ;3  3
            dec player_vdelay       ;5  8
            beq rider_A_to_B_end_a  ;2  10

rider_A_end_a
            dex                     ;2  12
            bpl rider_A_start       ;2  14
            jmp riders_end          ;3  17


;-----------------------------------------------------------------------------------
; Rider B Pattern 
; player + rider on same line


rider_B_start_0
            sta WSYNC               ;3   0 
            sta HMOVE               ;3   3 ; process hmoves
            pla                     ;4   7
            sta GRP0                ;3  10
            lda player_charge       ;3  13
            sta COLUPF              ;3  16
            pla                     ;4  20
            SLEEP 2                 ;2  22 ; timing shim
            sta RESP1               ;3  25  
            sta NUSIZ0              ;3  28
            sta HMP0                ;3  31 
            jmp rider_B_resp_end_0  ;3  34

rider_B_start_1
            sta WSYNC               ;3   0 
            sta HMOVE               ;3   3 ; process hmoves
            pla                     ;4   7
            sta GRP0                ;3  10
            lda player_charge       ;3  13
            sta COLUPF              ;3  16
            pla                     ;4  20
            SLEEP 4                 ;4  24 ; timing shim
            sta NUSIZ0              ;3  27
            sta RESP1               ;3  25  
            sta HMP0                ;3  29 
            jmp rider_B_resp_end_0  ;3  32

rider_B_start_l
            ; locate p1 at right edge of screen
            sta WSYNC               ;3   0 
            sta HMOVE               ;3   3
            pla                     ;4   7
            sta GRP0                ;3  10
            lda player_charge       ;3  13
            sta COLUPF              ;3  16
            pla                     ;4  20
            sta NUSIZ0              ;3  23
            ldy rider_hmov_0,x      ;4  30
            sty HMP1                ;3  33
            sta HMP0                ;3  26
            lda tmp                 ;3  36
            sbc #$04                ;2  38
            plp                     ;4  42
            bpl rider_B_to_A_resp_l ;2  44
rider_B_resp_l; strobe resp
            sbc #$01                ;2  46
            bpl rider_B_resp_l      ;2  58 (48 + 2 * 5)
            lda #$0                 ;2  60
            sta COLUPF              ;3  63
            SLEEP 4                 ;4  67 ; timing shim
            sta RESP1               ;3  70
            jmp rider_B_hmov        ;2  72
rider_B_to_A_resp_l; strobe resp
            sbc #$01                ;2  47
            bpl rider_B_to_A_resp_l ;2  59 (49 + 2 * 5)
            lda #$0                 ;2  61
            sta COLUPF              ;3  64
            sta ENABL               ;3  67
            sta RESP1               ;3  70
            jmp rider_A_hmov        ;3  73

rider_B_to_A_hmov
            lda #$0                 ;2  61
            sta COLUPF              ;3  64
            sta ENABL               ;3  67
            sta WSYNC
            sta HMOVE
            jmp rider_A_hmov_0

rider_B_to_A_loop
            lda #$0
            sta ENABL
            jmp rider_A_loop
rider_B_prestart
            ldy rider_hdelay,x     ;4  50
            dey                    ;2  52
            bmi rider_B_start_0    ;2  54
            dey                    ;2  56
            bmi rider_B_start_1    ;2  58
            sty tmp                ;3  61
            cpy #$05               ;2  63
            bpl rider_B_start_l    ;2  65
rider_B_start_n
            ; locate p1
            sta WSYNC               ;3   0 
            sta HMOVE               ;3   3 ; process hmoves
            pla                     ;4   7
            sta GRP0                ;3  10
            lda player_charge       ;3  13
            sta COLUPF              ;3  16
            pla                     ;4  20
            sta NUSIZ0              ;3  23
            SLEEP 2                 ;5  25 ; timing shim
rider_B_resp; strobe resp
            dey                     ;2  27
            bpl rider_B_resp        ;2  29 + hdelay * 5
            sta HMP0                ;3  32
            sta RESP1               ;3  35
rider_B_resp_end_0
            lda rider_hmov_0,x      ;4  42
            sta HMP1                ;3  45
            plp                     ;4  49
            bpl rider_B_to_A_hmov   ;2  51
            lda #$0                 ;2  53
            sta COLUPF              ;3  56

rider_B_hmov; locating rider horizontally
            sta WSYNC               ;3   0 
            sta HMOVE               ;3   3 ; process hmoves

            pla                     ;4   7
            sta GRP0                ;3  10
            lda player_charge       ;3  13
            sta COLUPF              ;3  16
            pla                     ;4  20
            sta NUSIZ0              ;3  23
            sta HMP0                ;3  49

            lda rider_color,x       ;4  29
            sta COLUP1              ;3  32
            lda rider_hmov_1,x      ;4  41
            sta HMP1                ;3  52
            ldy #RIDER_HEIGHT - 1   ;2  34
            lda #$00                ;2
            sta COLUPF              ;3  20
            plp                     ;5  46 BUGBUG exit
            bpl rider_B_to_A_loop   ;2  54

rider_B_loop  
            sta WSYNC               ;3   0
            sta HMOVE               ;3   3 ; process hmoves
            pla                     ;4   7
            sta GRP0                ;3  10
            lda player_charge       ;3  13
            sta COLUPF              ;3  16
            pla                     ;4  20
            sta NUSIZ0              ;3  23
            sta HMP0                ;3  26
            lda (rider_graphics),y  ;5  38 ; p1 draw
            sta GRP1                ;3  41
            lda (rider_ctrl),y      ;5  46
            sta NUSIZ1              ;3  49
            sta HMP1                ;3  52
            plp                     ;5  57 
            bpl rider_B_to_A_loop_a ;2  59
            lda #$0                 ;3  62
            sta COLUPF              ;3  65
rider_B_loop_a
            dey                     ;5  70
            bpl rider_B_loop        ;2  72

rider_B_end
            sta WSYNC               ;3   0
            sta HMOVE               ;3   3 ; process hmoves
            pla                     ;4   7
            sta GRP0                ;3  10
            lda player_charge       ;3  13
            sta COLUPF              ;3  16
            pla                     ;4  20
            sta NUSIZ0              ;3  23
            sta HMP0                ;3  26
            plp                     ;4  30  
            bpl rider_B_to_A_end_a  ;2  32

rider_B_end_a
            dex                      ;2  34
            bpl rider_B_prestart_jmp ;2  36
            lda #$0                  ;3  39
            sta COLUPF               ;3  42
            jmp riders_end           ;3  45
rider_B_prestart_jmp
            lda #$0                  ;3  40
            sta COLUPF               ;3  43
            jmp rider_B_prestart     ;3  46

rider_B_to_A_loop_a; running out of cycles in this transition
            lda #$0                ;3  63
            sta COLUPF             ;3  66
            sta ENABL              ;3  69
            dey                    ;2  71 ; copy rider_A_loop_a
            sta WSYNC              ;3  0  ; copy rider_A_end
            sta HMOVE              ;3  3
            bpl rider_B_to_A_loop_a_jmp ;2  5 
            jmp rider_A_end_a      ;3  8
rider_B_to_A_loop_a_jmp
            jmp rider_A_loop_body  ;3  9

rider_B_to_A_end_a
            lda #$0                ;2  37
            sta COLUPF             ;3  40
            sta ENABL              ;3  43
            jmp rider_A_end_a      ;3  46

;-----------------------------------------------------------------------------------
; sprite graphics
    ORG $F600

PLAYER_SPRITE_START
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

    ORG $F700

RIDER_SPRITE_START
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

    ORG $F7FA

    .word Reset          ; NMI
    .word Reset          ; RESET
    .word Reset          ; IRQ

    END