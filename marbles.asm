
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

SPEED = 3
PLAYFIELD_HEIGHT_BLOCKS = 20
PLAYFIELD_HEIGHT_PIX = PLAYFIELD_HEIGHT_BLOCKS * 2
NUM_PLAYERS = 4

#if SYSTEM = NTSC
; NTSC Colors
WHITE = $0F
GREY = $08
RED = $44
YELLOW = $1A
GREEN = $B6
BLUE = $82
BLACK = 0
#else
; PAL Colors
WHITE = $0E
GREY = $08
RED = $62
YELLOW = $2A
GREEN = $36
BLUE = $B2
BLACK = 0
#endif

; ----------------------------------
; macros

        MAC PLAYFIELD_BLOCKS
            lda BLOCK_PF0,y           ;4  14
            sta PF0                   ;3  17
            lda BLOCK_PF1,y           ;4  21
            sta PF1                   ;3  24
            lda BLOCK_PF2,y           ;4  28
            sta PF2                   ;3  31
            lda BLOCK_PF3,y           ;4  35
            sta PF0                   ;3  38
            lda BLOCK_PF4,y           ;4  42
            sta PF1                   ;3  45
            lda BLOCK_PF5,y           ;4  49
            sta PF2                   ;3  52
        ENDM

; ----------------------------------
; variables

  SEG.U variables

    ORG $80

; game state
frame               ds 1
blocks              ds 40
player_vpos         ds 4
missile_vpos        ds 4
missile_hpos        ds 4
missile_vvel        ds 4
missile_hvel        ds 4

; scratch vars
player_color        ds 2
missile_hindex      ds 2
missile_index       ds 2
player_index        ds 2
block_end_counter   ds 2
block_counter       ds 1
collision           ds 4

    SEG

; ----------------------------------
; code

  SEG
    ORG $F000

Reset

    ; do the clean start macro
            CLEAN_START            
            
initMissiles_start
            ldx #10
            stx player_vpos
            stx player_vpos+1
            stx player_vpos+2
            stx player_vpos+3
            ldx #$04
            stx missile_vpos
            stx missile_vpos+2
            ldx #$07
            stx missile_vpos+1
            stx missile_vpos+3
            ldx #$01
            stx missile_vvel
            stx missile_vvel + 2
            ldx #$ff
            stx missile_vvel + 1
            stx missile_vvel + 3
            ldx #$04
            stx missile_hpos
            stx missile_hpos + 2
            ldx #$07
            stx missile_hpos + 1
            stx missile_hpos + 3
            ldx #$10
            stx missile_hvel
            stx missile_hvel + 2
            ldx #$f0
            stx missile_hvel + 1
            stx missile_hvel + 3
initMissiles_end

initBlocks_start

            lda #PLAYFIELD_HEIGHT_BLOCKS
            ldy #PLAYFIELD_HEIGHT_BLOCKS * 2 - 1
initBlocks_loop
            sta blocks,y
            dey
            bpl initBlocks_loop
initblocks_end

newFrame

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

            dec frame
            bpl moveMissile_end
            lda #SPEED
            sta frame

            ldx #NUM_PLAYERS - 1
moveMissile_loop
            lda missile_vpos,x
            clc
            adc missile_vvel,x
            cmp #1
            bpl moveMissile_vgt0
            lda #$01
            sta missile_vvel,x
            jmp moveMissile_savev
moveMissile_vgt0
            cmp #PLAYFIELD_HEIGHT_PIX + 1
            bmi moveMissile_savev
            lda #$ff
            sta missile_vvel,x
            lda #PLAYFIELD_HEIGHT_PIX 
moveMissile_savev
            sta missile_vpos,x
moveMissile_horiz
            lda missile_hvel,x
            bmi moveMissile_right
            clc
            adc missile_hpos,x
            bvc moveMissile_left_limit
            adc #$0f
moveMissile_left_limit
            tay
            and #$0f
            cmp #$02
            bpl moveMissile_savehy
            cpy #$31
            bcs moveMissile_savehy
            lda #$f0
            sta missile_hvel,x
            ldy #$21
            jmp moveMissile_savehy
moveMissile_right
            clc
            adc missile_hpos,x
            bvc moveMissile_right_limit
            adc #$00 ; note carry is set
moveMissile_right_limit
            tay
            and #$0f
            cmp #$0b
            bmi moveMissile_savehy
            cpy #$ab
            bcc moveMissile_savehy
            lda #$10
            sta missile_hvel,x
            ldy #$ab
moveMissile_savehy
            tya
moveMissile_saveh
            sta missile_hpos,x
            dex
            bpl moveMissile_loop

moveMissile_end

;-- collision logic

            ldx #NUM_PLAYERS - 1
collideMissile_loop
            lda collision,x
            bpl collideMissile_next
            lda #PLAYFIELD_HEIGHT_PIX - 1
            sec
            sbc missile_vpos,x
            lsr 
            cpx #$02
            bcc collideMissile_no_offset
            adc #PLAYFIELD_HEIGHT_BLOCKS
collideMissile_no_offset
            tay
            txa 
            lsr
            bcs collideMissile_right
            lda blocks,y
            cmp #39
            bcs collideMissile_next
            clc
            adc #$01
            sta blocks,y 
            lda #$03
            sta missile_hpos,x
            jmp collideMissile_next
collideMissile_right
            lda blocks,y
            beq collideMissile_next
            sec
            sbc #$01
            sta blocks,y 
            lda #$09
            sta missile_hpos,x
collideMissile_next
            dex
            bpl collideMissile_loop

; setupBlocks_start
;             ldy #39
; setupBlocks_loop
;             ldx blocks,y
;             inx
;             cpx #41
;             bmi setupBlocks_save
;             ldx #$00
; setupBlocks_save
;             stx blocks,y
;             dey
;             bpl setupBlocks_loop
setupBlocks_end

            ldx #0
waitOnVBlank            
            cpx INTIM
            bmi waitOnVBlank

            stx VBLANK

;--------------------
; Screen start

            sta WSYNC
            lda #$00
            sta PF0
            sta PF1
            sta PF2
            sta COLUBK
            sta block_end_counter
            lda #PLAYFIELD_HEIGHT_BLOCKS
            sta block_counter
            lda #WHITE
            sta COLUP0
            sta COLUP1
            lda #BLUE
            sta player_color
            lda #RED
            sta player_color + 1
            lda player_vpos
            sta player_index
            lda player_vpos + 1
            sta player_index + 1
            lda missile_vpos
            sta missile_index
            lda missile_vpos + 1
            sta missile_index + 1
            lda missile_hpos
            sta missile_hindex
            lda missile_hpos + 1
            sta missile_hindex + 1
            sta CXCLR

            jsr playfield

            sta WSYNC
            lda #$00
            sta PF0
            sta PF1
            sta PF2
            lda CXM0FB 
            eor #$80   
            sta collision            
            lda CXM1FB
            sta collision + 1 
            sta COLUBK
            lda #PLAYFIELD_HEIGHT_BLOCKS
            sta block_end_counter
            lda #PLAYFIELD_HEIGHT_BLOCKS * 2 - 1
            sta block_counter         
            lda #GREEN
            sta player_color
            lda #YELLOW
            sta player_color + 1
            lda player_vpos + 2
            sta player_index
            lda player_vpos + 3
            sta player_index + 1
            lda missile_vpos + 2
            sta missile_index
            lda missile_vpos + 3
            sta missile_index + 1
            lda missile_hpos + 2
            sta missile_hindex
            lda missile_hpos + 3
            sta missile_hindex + 1
            sta CXCLR

            jsr playfield

            sta WSYNC
            lda #$00
            sta PF0
            sta PF1
            sta PF2
            sta COLUBK
            lda CXM0FB              
            eor #$80   
            sta collision + 2          
            lda CXM1FB              
            sta collision + 3
            jmp overscan

playfield
    ; locate missile 0
            sta WSYNC
            lda missile_hindex
            sta HMM0
            and #$0F
            tax
missile_0_resp
            dex 
            bpl missile_0_resp
            sta RESM0

            sta WSYNC
    ; locate missile 1
            lda missile_hindex+1
            sta HMM1
            and #$0F
            tax
missile_1_resp
            dex 
            bpl missile_1_resp
            sta RESM1

            sta WSYNC
            sta HMOVE
            lda player_color
            sta COLUPF
            lda player_color+1        ;3   3
            sta COLUBK                ;3   6
            ldx block_counter

playfield_loop_block
            ldy blocks,x              ;4  --/72

            sta WSYNC                 ;3   0
            dec missile_index         ;5   5
            dec missile_index + 1     ;5  10
            PLAYFIELD_BLOCKS          ;42 52
            lda missile_index         ;3  55
            beq missile_0_A           ;2  57
            lda #$ff                  ;2  59
missile_0_A
            eor #$ff                  ;2  61
            sta ENAM0                 ;3  64
            lda missile_index+1       ;3  67
            beq missile_1_A           ;2  69
            lda #$ff                  ;2  71
missile_1_A
            eor #$ff                  ;2  73
            sta ENAM1                 ;3  76

;            sta WSYNC                 ;3   0
            SLEEP 10                  ;   10
            PLAYFIELD_BLOCKS          ;42 52
            sta WSYNC                 ;3   0
            dec missile_index         ;5   5
            dec missile_index + 1     ;5  10
            PLAYFIELD_BLOCKS          ;42 52
            lda missile_index         ;3  55
            beq missile_0_B           ;2  57
            lda #$ff                  ;2  59
missile_0_B
            eor #$ff                  ;2  61
            sta ENAM0                 ;3  64
            lda missile_index+1       ;3  67
            beq missile_1_B           ;2  69
            lda #$ff                  ;2  71
missile_1_B
            eor #$ff                  ;2  73
            sta ENAM1                 ;3  76

;            sta WSYNC                 ;3   0
            SLEEP 10                  ;   10
            PLAYFIELD_BLOCKS          ;42 52

            ldx block_counter         ;3  55
            dex                       ;2  57
            cpx block_end_counter     ;3  60
            bmi playfield_end         ;2  62
            stx block_counter         ;3  65
            jmp playfield_loop_block  ;3  68

playfield_end
            rts                       ;6  69

;--------------------
; Overscan start
overscan
            ldx #30
waitOnOverscan
            sta WSYNC
            dex
            bne waitOnOverscan

            jmp newFrame

;--------------------
; Block Graphics

    ORG $FF00

BLOCK_PF0 byte $00,$10,$30,$70,$F0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
BLOCK_PF1 byte $00,$00,$00,$00,$00,$80,$C0,$E0,$F0,$F8,$FC,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
BLOCK_PF2 byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$03,$07,$0F,$1F,$3F,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
BLOCK_PF3 byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$10,$30,$70,$F0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF                   
BLOCK_PF4 byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$C0,$E0,$F0,$F8,$FC,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
BLOCK_PF5 byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$03,$07,$0F,$1F,$3F,$7F,$FF

;--------------------
; Reset

    ORG $FFFA

    .word Reset          ; NMI
    .word Reset          ; RESET
    .word Reset          ; IRQ

    END