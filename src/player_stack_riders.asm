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
BROWN = $F0
RIDER_HEIGHT = 24
NUM_RIDERS = 5
PLAYER_COLOR = BLACK
PLAYER_START_HEALTH = 10
RIDER_ANIMATE_SPEED = 3
PLAYER_ANIMATE_SPEED = 3
PLAYER_STRIKE_COUNT = 48
RIDER_RESP_START = 8
RIDER_GREEN_TYPE = $44
RAIL_HEIGHT = 6
LOGO_HEIGHT = 6
WINNING_SCORE = $11
; ----------------------------------
; variables

  SEG.U variables

    ORG $80

game_state      ds 1
rider_animate   ds 1
rider_timer     ds 5
rider_ctrl      ds 2
rider_graphics  ds 2
rider_hdelay    ds 5
rider_hmov_0    ds 5
rider_type      ds 5
rider_hit       ds 5
rider_damaged   ds 5
rider_pattern   ds 1
player_animate  ds 1
player_ctrl     ds 2
player_graphics ds 2
player_vdelay   ds 1
player_vpos     ds 1
player_hmov     ds 1
player_hmov_x   ds 1
player_charge   ds 1
player_fire     ds 1
player_damaged  ds 1
player_health   ds 1
player_score    ds 1
tmp                  ; overlapping ram
score_addr_0    ds 2 ; used in scoring kernels
score_addr_1    ds 2 ; used in scoring kernels

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
            ldx #$3f
.zapTIA     sta 0,x
            dex
            bpl .zapTIA

            ldx #127
.zapRAM     sta $80,x
            dex
            bpl .zapRAM

  ; black playfield sidebars, on top of players
            lda #$30
            sta PF0
            lda #$05
            sta CTRLPF

init_game
  ; rider positions
            lda #>PLAYER_SPRITE_START
            sta player_ctrl+1
            sta player_graphics+1
            lda #<PLAYER_SPRITE_0_CTRL
            sta player_ctrl
            lda #<PLAYER_SPRITE_0_GRAPHICS
            sta player_graphics

            lda #>RIDER_SPRITE_START
            sta rider_ctrl+1
            sta rider_graphics+1
            lda #<RIDER_SPRITE_0_CTRL
            sta rider_ctrl
            lda #<RIDER_SPRITE_0_GRAPHICS
            sta rider_graphics

            ldx #NUM_RIDERS - 1
init_rider_loop
            lda #RIDER_GREEN_TYPE
            sta rider_type,x
            lda #$70
            sta rider_hmov_0,x
            lda #$ff
            sta rider_damaged,x
            dex
            bpl init_rider_loop

            ldx #RIDER_ANIMATE_SPEED

            ldx #$28
            stx player_vpos
            stx rider_pattern

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

;--------------------
; VBlank start
; SL 0-6 
            lda #1
            sta VBLANK
            ldx #$06
vBlank      sta WSYNC
            dex
            bne vBlank

;---------------------
; scoring kernel
; SL 6/7-11
            ldx #NUM_RIDERS - 1 
            dec player_damaged
            bpl scoringLoop
            lda #0
            sta player_damaged
scoringLoop
            sta WSYNC
            lda rider_type,x
            cmp #RIDER_GREEN_TYPE
            beq scoringLoop_end         
            lda rider_damaged,x
            bpl scoringLoop_decay
            lda rider_hit,x
            and #$80
            beq scoringLoop_end
            lda #$0
            sta rider_hit,x
            ; hit scored
            lda player_fire
            beq scoringLoop_player_hit
scoringLoop_rider_hit
            sed
            lda player_score
            adc #$01
            sta player_score
            cld
            lda #$10
            sta rider_damaged,x
            jmp scoringLoop_end
scoringLoop_player_hit
            asl player_health
            lda #$10
            sta player_damaged
            lda #$0
            sta player_charge
scoringLoop_decay
            sbc #$01
            bmi scoringLoop_rider_clear
            sta rider_damaged,x
            inc rider_type,x
            jmp scoringLoop_end
scoringLoop_rider_clear
            lda #RIDER_GREEN_TYPE
            sta rider_type,x
            lda #$ff
            sta rider_damaged,x
scoringLoop_end
            dex
            bpl scoringLoop

;-----------------------------
; animate player
; SL 12 (-26 till picture)
animatePlayer
            sta WSYNC
            lda game_state           
            beq animatePlayer_end           
            lda player_damaged
            beq animatePlayer_seq
            ldy #<PLAYER_SPRITE_3_CTRL
            lda #<PLAYER_SPRITE_3_GRAPHICS
            jmp animatePlayer_save
animatePlayer_seq
            dec player_animate
            bpl animatePlayer_end
            lda player_ctrl
            cmp #<PLAYER_SPRITE_2_CTRL
            bmi animatePlayer_inc
            ldy #<PLAYER_SPRITE_0_CTRL
            lda #<PLAYER_SPRITE_0_GRAPHICS
            jmp animatePlayer_save
animatePlayer_inc
            clc
            adc #48
            tay
            lda player_graphics
            adc #48
animatePlayer_save
            sty player_ctrl
            sta player_graphics
            lda #PLAYER_ANIMATE_SPEED
            sta player_animate
animatePlayer_end

; SL 12-21 
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

animatePlayer_eval_fire 
            dec player_fire
            bpl animatePlayer_fire_active
            lda #$00
            sta player_fire
            jmp animatePlayer_fire_end
animatePlayer_fire_active
            lda #$ff 
            sta $dd
animatePlayer_fire_end

; SL 22
            sta WSYNC                ;3   0
            lda game_state           ;3   3    
            bne movePlayer           ;2   5
movePlayer_game
; SL 23
            sta WSYNC
            lda #$80                 ;3   8
            bit INPT4                ;3  11
            bne movePlayer_game_check;2  13
            lda #1
            sta player_charge        ;5  18
            jmp movePlayer_end
movePlayer_game_check
            lda player_charge
            beq movePlayer_end
            lda #$0
            sta player_charge
            sta player_score
            ldx #$ff
            stx player_health
            lda #$23
            sta game_state
            jmp movePlayer_end

movePlayer
            lda player_damaged       ;3   3
            bne movePlayer_dir       ;2   5
            lda #$80                 ;3   8
            bit INPT4                ;3  11
            bne movePlayer_button_up ;2  13
            inc player_charge        ;5  18
            jmp movePlayer_dir       ;3  21
movePlayer_button_up
            lda player_charge             ;3  24
            beq movePlayer_button_up_done ;2  26
            lda #PLAYER_STRIKE_COUNT      ;2  28
            sta player_fire               ;3  31
movePlayer_button_up_done
            lda #0               ;2  33
            sta player_charge    ;3  36

movePlayer_dir
; SL 23
            sta WSYNC            ;3   0
            lda player_fire
            bne movePlayer_fire
            lda #$00
            sta player_hmov_x
            lda #$80             ;3  34 kludge reloading
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

movePlayer_fire
            lda #$80             ;2
            sta player_hmov_x    ;3
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

; SL 24
            sta WSYNC 
animateRider
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
            ldx #RIDER_ANIMATE_SPEED
            stx rider_animate
animateRider_end

            ldx #NUM_RIDERS - 1

; SL 25-34           
moveRider_loop
            sta WSYNC
            lda game_state            ;3   3    
            beq moveRider_noreset     ;2   5
            dec rider_timer,x         ;6  11
            bpl moveRider_noreset     ;2  13
            lda rider_type,x          ;4  17
            lsr                       ;2  19
            lsr                       ;2  21
            lsr                       ;2  23
            lsr                       ;2  25
            sta rider_timer,x         ;4  29
            lda #$10                  ;2  31
            clc                       ;2  33
            adc rider_hmov_0,x        ;4  37
            bvs moveRider_dec_hdelay  ;2  39
            sta rider_hmov_0,x        ;4  43  
            jmp moveRider_noreset     ;3  46
moveRider_dec_hdelay
            lda #$90              ;2  42
            sta rider_hmov_0,x    ;4  46  
            dec rider_hdelay,x    ;6  52
            bpl moveRider_noreset ;2  54
moveRider_reset
            ; reset rider
            lda #RIDER_RESP_START  ;2  56
            sta rider_hdelay,x     ;4  60
            lda #$b0               ;2  62 ; adjust hmov to avoid wraparound
            sta rider_hmov_0,x     ;4  66  
            lda rider_pattern      ;3  69 ; Galois LFSA
            lsr                    ;2  71 ; see https://samiam.org/blog/20130617.html
            bcc moveRider_skipEor  ;2  73
            eor #$8e               ;2  75
moveRider_skipEor
            sta rider_pattern      ;3  78 
            ; lsr                       ;2  67
            ; bcc moveRider_chooseColor ;2  69
            ; lda #RIDER_GREEN_TYPE     ;2  71
            ; jmp moveRider_skipCycle   ;3  74
moveRider_chooseColor
            and game_state         ;3   81
moveRider_skipCycle
            sta rider_type,x       ;4   85
            jmp moveRider_end      ;3   88
moveRider_noreset
            sta WSYNC              ;3    0
moveRider_end
            dex                    ;2   90
            bpl moveRider_loop     ;2   92

; -----------------------------------
; Display kernels
; 192 scanlines of picture to follow
; ----------------------------------

; horizon kernel(s)
; 36 variable width bands of color gradient 

; horizon + score kernel
; SL 35

            sta WSYNC
            lda #$b0               ;2   2
            sta HMP0               ;3   5
            adc #$20               ;2   7
            sta HMP1               ;3  10
            ldx #$09               ;3  13
horizonScore_resp
            dex                    ;2  15
            bpl horizonScore_resp  ;2  62 (17 + 45)
            sta RESP0              ;3  65
            sta RESP1              ;3  68
; SL 36
            sta WSYNC
            sta HMOVE              ;3   3
            lda #WHITE             ;2   5
            sta COLUP0             ;3   8
            sta COLUP1             ;3  11
            lda #0                 ;2  13 ; end of VBLANK
            sta VBLANK             ;3  16

            ldx #13                ;2  18  
; SL 37 (Display 0)
            sta WSYNC
            lda HORIZON_COLOR,x      ;4   4 
            sta COLUBK               ;3   7
            lda player_score
            and #$0f
            asl
            asl
            asl
            adc #<FONT_0
            sta score_addr_1
            lda #>FONT_0
            sta score_addr_1 + 1
            lda player_score
            lsr
            lsr
            lsr
            lsr
            asl
            asl
            asl
            adc #<FONT_0
            sta score_addr_0
            lda #>FONT_0
            sta score_addr_0 + 1
            ldy #$07

; SL 38-45
horizonScore_Loop
            sta WSYNC
            lda player_health        ;3   3
            sta PF1                  ;3   6
            lda HORIZON_COLOR,x      ;4  10 
            sta COLUBK               ;3  13
            lda (score_addr_0),y       ;5  18
            sta GRP0                 ;3  21
            lda #RED                 ;2  23
            sta COLUPF               ;3  26
            lda (score_addr_1),y       ;5  31
            sta GRP1                 ;3  34
            SLEEP 5
            lda #$00
            sta COLUPF
            sta PF1
            dey                      ;2  23
            bmi horizonScore_End     ;2  25
            tya                      ;2  27
            cmp HORIZON_COUNT,x      ;4  31
            bpl horizonScore_Loop    ;2* 33
            dex                      ;2  35
            jmp horizonScore_Loop    ;3  38

horizonScore_End

; horizon + sun kernel 
; SL 46
            ldy #$04                 ;2  48
            sta WSYNC
            lda HORIZON_COLOR,x      ;4   4 
            sta COLUBK               ;3   7
            lda #0                   ;2   9
            sta GRP0                 ;3  12
            sta GRP1                 ;3  15
horizonSun_resp
            dey                      ;2  17
            bpl horizonSun_resp      ;2  39 (19 + 20)
            sta RESP0                ;3  42
            sta RESP1                ;3  45
            lda #0                   ;2  47
            sta HMP0                 ;3  50
            sta NUSIZ1               ;3  53
            lda #$10                 ;2  55
            sta HMP1                 ;3  58
            lda #1                   ;2  60             
            sta NUSIZ0               ;3  63

; SL 47
horizonSun_hmov
            sta WSYNC                ;3   0
            sta HMOVE                ;3   3
            lda HORIZON_COLOR,x      ;4   4 
            sta COLUBK               ;3   7
            lda #SUN_RED             ;2   5
            sta COLUP0               ;3   8
            sta COLUP1               ;3  11
            dex                      ;2  13 ; hardcode

; SL 48 ... 72

            ldy #24                  ;2  15
horizonLoop
            sta WSYNC                ;3   0 
            lda HORIZON_COLOR,x      ;4   4 
            sta COLUBK               ;3   7
            lda SUN_SPRITE_LEFT,y    ;4  11 
            sta GRP0                 ;3  14
            lda SUN_SPRITE_MIDDLE,y  ;4  18  
            sta GRP1                 ;3  21
            lda #0                   ;2  23
            sta REFP0                ;3  26
            dey                      ;2  28
            bmi horizonEnd           ;2  30
            clc                      ;2  32
            lda #2                   ;2  34
horizonLoop_refp
            sbc #1                   ;2  36
            bpl horizonLoop_refp     ;2  48 (38 + 10)
            lda #8                   ;2  50
            sta REFP0                ;3  53
            tya                      ;2  55
            cmp HORIZON_COUNT,x      ;4  59
            bpl horizonLoop          ;2* 61
            dex                      ;2  62
            jmp horizonLoop          ;3  65
horizonEnd
            lda #0                   ;2  33
            sta GRP0                 ;3  36
            sta GRP1                 ;3  39
            sta REFP0                ;3  42
            sta NUSIZ0               ;3  45
            sta NUSIZ1               ;3  48
            sta HMCLR                ;3  51

; ----------------------------------
; playfield kernel 
;
; locating player first
;
    ; SC 73           
            sta WSYNC                ;3   0
            lda #GREEN               ;2   2
            sta COLUBK               ;3   5
            ldy #4                   ;2   7
player_resp_loop
            dey                      ;2   9
            bpl player_resp_loop     ;2  11 + 20 = 31
            sta RESP0                ;3  34
            lda #PLAYER_COLOR        ;2  36
            sta COLUP0               ;3  39
            lda player_vpos          ;3  42 
            sta player_vdelay        ;3  45

    ; SC 74
            sta WSYNC                ;3   0
            lda player_hmov          ;3   3
            ldy #4                   ;2   5
yari_resp_loop
            dey                      ;2   7
            bpl yari_resp_loop       ;2   9 + 20 = 29
            sta RESBL                ;3  32
            sta HMP0                 ;3  35
            sta HMBL                 ;3  38

    ; SC 75
            sta WSYNC                ;3   0
            ldx #$03                 ;3   3
player_boost_delay
            dex                      ;2   5
            bpl player_boost_delay   ;2  22 (7 + 3 * 5)
            lda player_hmov_x        ;3  25
            sta HMP0                 ;3  28
            lda #$00                 ;2  30
            sta HMBL                 ;3  33

    ; SC 76
            sta WSYNC                ;3   0
            sta HMOVE                ;3   3

;-------------------
; top rail kernel

    ; SC 77 .. 85
            ldx #RAIL_HEIGHT         ;2  10
rail_A_loop 
            sta WSYNC                ;3   0
            dex                      ;2   2
            bne rail_A_loop          ;2   4

;--------------------
; riders kernel
; x loaded with current rider 
; y used for rider graphics index
; sp used for player graphics index


    ; SC 86 .. 219 (27 * 5)
riders_start
            stx HMP0                 ;3   7
            sta CXCLR                ;3  13
            ldx #NUM_RIDERS - 1      ;2  15
            jmp rider_A_start        ;3  17

riders_end

;--------------------
; bottom rail kernel
;
            ldx #RAIL_HEIGHT
rail_B_loop  
            sta WSYNC
            dex
            bne rail_B_loop

;
    ; SC 180
            lda #BLACK
            sta COLUBK
            ldx #LOGO_HEIGHT
logo_loop 
            sta WSYNC
            dex
            bne logo_loop

    ; SC 192
    ; 30 lines of overscan to follow            

            ldx #30
doOverscan  sta WSYNC               ; wait a scanline
            dex
            bne doOverscan
            lda #$01
            bit SWCHB
            bne gameCheck
            jmp Reset
gameCheck
            lda player_score
            cmp #WINNING_SCORE
            bpl gameEnd
            lda player_health
            bne gameContinue
gameEnd
            lda #0
            sta game_state
gameContinue
            jmp newFrame

;-----------------------------------------------------------------------------------
; Rider A Pattern
; rider only, waiting for player
; rider timings
; RESPx DELAY CHART
; A Y0 SC 22 PP  12
; A Y1 SC 27 PP  27
; A Y2 SC 32 PP  42
; A Y3 SC 37 PP  57
; A Y4 SC 42 PP  72
; A Y5 SC 47 PP  87
; A Y6 SC 52 PP 102
; A Y7 SC 57 PP 117
; A Y8 SC 62 PP 132
; A Y9 SC 67 PP 147

rider_A_to_B_hmov
            lda player_fire           ;3  64
            bne rider_A_to_B_hmov_jmp ;2  66
            sty HMBL                  ;3  69  ; trick - y is $ff
            sty ENABL                 ;3  72
rider_A_to_B_hmov_jmp
            sta WSYNC                 ;3   0
            sta HMOVE                 ;3   3
            jmp rider_B_hmov_a        ;3   6

rider_A_start_l
            dec player_vdelay        ;5  21
            beq rider_A_to_B_start_l ;2  23
            sta HMP1                 ;3  26
            dey                      ;2  28
rider_A_resp_l; strobe resp
            dey                      ;2  30
            bne rider_A_resp_l       ;2+ 67 (32 + 7 * 5)
            sta RESP1                ;3  70 
            jmp rider_A_hmov            

rider_A_to_B_start_l
            sta HMP1                   ;3  27
            tya                        ;2  29
            ldy player_fire            ;3  32
            bne rider_A_to_B_resp_shim ;2  34
            ldy #$ff                   ;2  36
            sty HMBL                   ;3  39
            sty ENABL                  ;3  42
            SLEEP 3                    ;2  45 timing shim
            sbc #$07                   ;2  47
            jmp rider_A_to_B_resp_m    ;3  50
rider_A_to_B_resp_shim
            sbc #$05                   ;2  37
            jmp rider_A_to_B_resp_m    ;3  40
rider_A_to_B_resp_l; strobe resp
            sbc #$01                   ;2  --
rider_A_to_B_resp_m; strobe resp
            bpl rider_A_to_B_resp_l    ;2+ 67 (42/52 + 5/3 * 5)
            sta RESP1                  ;3  70 
            jmp rider_B_hmov

rider_A_start
            ; locate p1
            sta WSYNC               ;3   0 
            sta HMOVE               ;3   3
            lda rider_hmov_0,x      ;4   7
            ldy rider_hdelay,x      ;4  11
            cpy #$06                ;2  13
            bpl rider_A_start_l     ;2  15
            jmp rider_A_resp        ;3  18 timing shim
rider_A_resp; strobe resp 
            dey                     ;2  20
            bpl rider_A_resp        ;2+ 47 (22 + 5 * 5)
            sta RESP1               ;3  50 
            sta HMP1                ;3  53
            dec player_vdelay       ;5  58
            beq rider_A_to_B_hmov   ;2  60

rider_A_hmov; locating rider horizontally 2
            sta WSYNC                     ;3   0 
            sta HMOVE                     ;3   3 ; process hmoves
rider_A_hmov_0; from rider B
            lda rider_type,x              ;4   7
            and #$0f                      ;2   9
            tay                           ;2  11
            lda RIDER_COLORS,y            ;4  15
            sta COLUP1                    ;3  18
            lda #$0                       ;2  20
            ldy #RIDER_HEIGHT - 1         ;2  22
            dec player_vdelay             ;5  27
            sta CXCLR                     ;3  30 prep for collision
            sta HMP1                      ;3  33
            beq rider_A_to_B_loop         ;2  35

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
            lda CXPPMM              ;2  12 / 48 (from b)    
            sta rider_hit,X         ;4  16 / 52
            dex                     ;2  18 / 54
            bpl rider_A_start       ;2  20 / 56
            jmp riders_end          ;3  23 / 59

rider_A_to_B_loop
            lda player_fire
            bne rider_A_to_B_loop_jmp
            lda #$ff                ;2  31
            sta HMBL                ;3  34
            sta ENABL               ;3  37
rider_A_to_B_loop_jmp
            jmp rider_B_loop        ;3  40

rider_A_to_B_loop_a
            lda player_fire
            bne rider_A_to_B_loop_a_jmp
            lda #$ff                ;2  31
            sta HMBL                ;3  34
            sta ENABL               ;3  37
rider_A_to_B_loop_a_jmp
            jmp rider_B_loop_a       ;3  40

rider_A_to_B_end_a
            lda player_fire
            bne rider_A_to_B_end_a_jmp
            lda #$ff                ;2  12
            sta ENABL               ;3  15
            sta HMBL                ;3  18
rider_A_to_B_end_a_jmp
            jmp rider_B_end_a       ;3  21

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
            ldy #$0                 ;2  33
            jmp rider_B_resp_end_0  ;3  36

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
            ldy #$0                 ;2  31
            jmp rider_B_resp_end_0  ;3  34

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
            sty COLUPF              ;3  72 ;
            sta WSYNC               ;3   0 ;
            sta HMOVE               ;3   3 ; transition from B_to_A
            sty ENABL               ;3   9 ; interleave with rider_A_hmov
            jmp rider_A_hmov_0      ;3  12

rider_B_prestart
            lda #$0                ;3  49
            sta COLUPF             ;3  52
            ldy rider_hdelay,x     ;4  56
            dey                    ;2  58
            bmi rider_B_start_0    ;2  60
            dey                    ;2  62
            bmi rider_B_start_1    ;2  64
            sty tmp                ;3  67
            cpy #$05               ;2  69
            bpl rider_B_start_l    ;2  71
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
rider_B_resp; strobe resp
            dey                     ;2  25
            bpl rider_B_resp        ;2  47  27 + 4 * 5
            sta HMP0                ;3  49
            ldy #$0                 ;2  52
            sta RESP1               ;3  55
rider_B_resp_end_0
            lda rider_hmov_0,x      ;4  59
            sta HMP1                ;3  62
            plp                     ;4  66
            bpl rider_B_to_A_hmov   ;2  68
            sty COLUPF              ;3  71

rider_B_hmov; locating rider horizontally
            sta WSYNC               ;3   0 
            sta HMOVE               ;3   3 ; process hmoves
rider_B_hmov_a
            pla                     ;4   7
            sta GRP0                ;3  10
            lda player_charge       ;3  13
            sta COLUPF              ;3  16
            pla                     ;4  20
            sta NUSIZ0              ;3  23
            sta HMP0                ;3  26
            lda rider_type,x        ;4  30
            and #$0f                ;2  32
            tay                     ;2  34
            lda RIDER_COLORS,y      ;4  38
            sta COLUP1              ;3  41
            lda #$00                ;4  45
            sta HMP1                ;3  48
            ldy #RIDER_HEIGHT - 1   ;2  50
            sta CXCLR               ;3  53 prep for collision
            sta COLUPF              ;3  56
            plp                     ;5  61  exit
            bpl rider_B_to_A_loop   ;2  63

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
            lda CXPPMM               ;2  34     
            sta rider_hit,X          ;4  38
            dex                      ;2  40
            bpl rider_B_prestart_jmp ;2  42
            lda #$0                  ;3  45
            sta COLUPF               ;3  48
            jmp riders_end           ;3  51

rider_B_prestart_jmp
            jmp rider_B_prestart     ;3  46

rider_B_to_A_loop
            lda #$0
            sta ENABL
            jmp rider_A_loop

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
            sta ENABL              ;3  40
            sta COLUPF             ;3  43
            jmp rider_A_end_a      ;3  46

;-----------------------------------------------------------------------------------
; sprite graphics

FONT_0
        byte $3c,$7e,$66,$66,$66,$66,$7e,$3c; 8
FONT_1
        byte $7e,$7e,$18,$18,$18,$18,$78,$78; 8
FONT_2
        byte $7e,$7e,$40,$7e,$7e,$6,$7e,$7e; 8
FONT_3
        byte $7e,$7e,$6,$7e,$7e,$6,$7e,$7e; 8
FONT_4
        byte $6,$6,$6,$7e,$7e,$66,$66,$66; 8
FONT_5
        byte $7e,$7e,$6,$7e,$7e,$60,$7e,$7e; 8
FONT_6
        byte $7e,$7e,$66,$7e,$7e,$60,$7e,$7e; 8
FONT_7
        byte $6,$6,$6,$6,$6,$6,$7e,$7e; 8
FONT_8
        byte $7e,$7e,$66,$7e,$7e,$66,$7e,$7e; 8
FONT_9
        byte $6,$6,$6,$7e,$7e,$66,$7e,$7e; 8

    ORG $F600

PLAYER_SPRITE_START
PLAYER_SPRITE_0_CTRL
    byte $0,$5,$15,$15,$15,$5,$f5,$5,$5,$f7,$35,$c7,$55,$d7,$65,$5,$f5,$5,$50,$10,$0,$0,$0,$0; 24
PLAYER_SPRITE_0_GRAPHICS
    byte $0,$8a,$92,$a2,$ce,$e6,$77,$7f,$7f,$f8,$ff,$f8,$ff,$f8,$ef,$77,$73,$b2,$f0,$e0,$f0,$60,$90,$90; 24
PLAYER_SPRITE_1_CTRL
    byte $0,$5,$f5,$f5,$5,$15,$f5,$5,$5,$5,$d7,$35,$d7,$55,$25,$5,$f5,$25,$30,$10,$0,$0,$0,$0; 24
PLAYER_SPRITE_1_GRAPHICS
    byte $0,$ab,$af,$a6,$c2,$c6,$e7,$fe,$fe,$ff,$f8,$ff,$f8,$ff,$ef,$77,$b3,$e4,$f0,$e0,$f0,$60,$90,$90; 24
PLAYER_SPRITE_2_CTRL
    byte $0,$5,$f5,$5,$f5,$5,$d5,$5,$5,$f7,$35,$c7,$55,$d7,$65,$5,$f5,$5,$40,$20,$0,$0,$0,$0; 24
PLAYER_SPRITE_2_GRAPHICS
    byte $0,$44,$44,$e5,$c5,$cf,$73,$7f,$7f,$f8,$ff,$f8,$ff,$f8,$ef,$77,$73,$b2,$78,$f0,$60,$90,$90,$0; 24
PLAYER_SPRITE_3_CTRL
    byte $0,$0,$5,$5,$f5,$5,$17,$5,$5,$d7,$15,$e7,$35,$f7,$25,$25,$15,$5,$25,$f5,$0,$0,$0,$0; 24
PLAYER_SPRITE_3_GRAPHICS
    byte $0,$66,$a4,$66,$63,$63,$d8,$e7,$ff,$f8,$7f,$f8,$7f,$f8,$7f,$3f,$7f,$7f,$ce,$f6,$f3,$60,$90,$90; 24

SUN_SPRITE_LEFT ; 26
        byte $ff,$ff,$ff,$ff,$7f,$7f,$7f,$7f,$3f,$3f,$3f,$1f,$1f,$f,$f,$7,$3,$1,$0,$0,$0,$0,$0,$0,$0
SUN_SPRITE_MIDDLE ; 26
        byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$3c,$0,$0,$0,$0,$0

    ORG $F700

RIDER_SPRITE_START
RIDER_SPRITE_0_CTRL
    byte $0,$5,$f5,$f5,$5,$5,$f5,$f5,$5,$17,$f5,$7,$f5,$f7,$e5,$5,$15,$5,$50,$0,$10,$0,$0,$0; 24
RIDER_SPRITE_0_GRAPHICS
    byte $0,$51,$49,$45,$77,$67,$6f,$7f,$7f,$f8,$ff,$f8,$ff,$f8,$f7,$ee,$ce,$4d,$3c,$38,$f0,$60,$90,$90; 24
RIDER_SPRITE_1_CTRL
    byte $0,$5,$15,$35,$f5,$f5,$5,$15,$5,$f5,$f7,$5,$f7,$f7,$e5,$5,$15,$25,$40,$0,$0,$0,$0,$0; 24
RIDER_SPRITE_1_GRAPHICS
    byte $0,$9f,$af,$9e,$86,$c6,$ef,$fe,$fe,$ff,$f8,$ff,$f8,$f8,$f7,$ee,$cd,$9c,$78,$70,$f0,$60,$90,$90; 24
RIDER_SPRITE_2_CTRL
    byte $0,$5,$f5,$5,$15,$15,$5,$5,$5,$17,$f5,$7,$f5,$f7,$e5,$5,$15,$5,$40,$0,$20,$0,$0,$0; 24
RIDER_SPRITE_2_GRAPHICS
    byte $0,$44,$22,$a7,$a3,$e7,$67,$7f,$7f,$f8,$ff,$f8,$ff,$f8,$f7,$ee,$ce,$4d,$1e,$3c,$60,$90,$90,$0; 24
RIDER_SPRITE_3_CTRL
    byte $0,$0,$b5,$f5,$f5,$5,$f7,$15,$5,$27,$5,$7,$f5,$f7,$e5,$f5,$5,$5,$15,$15,$50,$40,$0,$0; 24
RIDER_SPRITE_3_GRAPHICS
    byte $0,$33,$4a,$4e,$43,$47,$f8,$e7,$ff,$f8,$fe,$f8,$fe,$f8,$7f,$7e,$fe,$fe,$ce,$96,$cf,$60,$90,$90; 24

RIDER_COLORS ; 5 bytes
        byte BROWN, RED, WHITE, YELLOW, GREEN

HORIZON_COLOR ; 14 bytes
        byte CLOUD_ORANGE - 2, CLOUD_ORANGE, CLOUD_ORANGE + 2, CLOUD_ORANGE + 4, 250, 252, 254, 252, 250, WHITE_WATER, SKY_BLUE + 8, SKY_BLUE + 4, SKY_BLUE + 2, SKY_BLUE 
HORIZON_COUNT ; 14 bytes
        byte $0, $2, $4, $6, $7, $8, $b, $13, $16, $17, $18, $0, $2, $4 
   
;-----------------------------------------------------------------------------------
; the CPU reset vectors

    ORG $F7FA

    .word Reset          ; NMI
    .word Reset          ; RESET
    .word Reset          ; IRQ

    END