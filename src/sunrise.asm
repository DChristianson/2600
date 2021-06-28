            processor 6502
            include "vcs.h"
            include "macro.h"

SKY_BLUE = 160
DARK_WATER = 160
SUN_RED = 48
CLOUD_ORANGE = 34
GREY_SCALE = 2 
WHITE_WATER = 10

            SEG.U variables
            ORG $80
timer_count DS 1

            SEG
            ORG $F000
Reset

            lda #0
            sta timer_count


StartOfFrame
   ; Start of vertical blank processing

            lda #0
            sta VBLANK

            lda #2
            sta VSYNC
               ; 3 scanlines of VSYNCH signal...
                sta WSYNC
                sta WSYNC
                sta WSYNC

            lda #0
            sta VSYNC       

               ; cls
                ldx #0
                stx COLUBK

              ; ready sun playfield
                ldy #SUN_RED
                sty COLUPF  
                ldy #0
                sty PF2  
                ldy #1
                sty CTRLPF

               ; 37 scanlines of vertical blank...
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
            

               ; 192 scanlines of picture...
 
                ldx #160
                stx COLUBK
                REPEAT 20; 20 scanlines
                    sta WSYNC
                REPEND

                ldx #162
                stx COLUBK
                REPEAT 10; 30 scanlines 
                    sta WSYNC
                REPEND

                ldx #164
                stx COLUBK
                REPEAT 2; 32 scanlines
                    sta WSYNC
                REPEND

                ldx #168
                stx COLUBK
                REPEAT 1; 33 scanlines
                    sta WSYNC
                REPEND

                ldx #8
                stx COLUBK
                REPEAT 2; 35 scanlines
                    sta WSYNC
                REPEND

                ldx #250
                stx COLUBK
                REPEAT 5; 40 scanlines
                    sta WSYNC
                REPEND

                ldx #252
                stx COLUBK
                REPEAT 5; 45 scanlines
                    sta WSYNC
                REPEND

                ldx #254
                stx COLUBK
                REPEAT 46; 91 scanlines
                    sta WSYNC
                REPEND

                ldy #128
                sty PF2  
                sta WSYNC ; 92 scanlines
                sta WSYNC ; 93 scanlines

                ldy #192
                sty PF2  
                sta WSYNC ; 94 scanlines
                sta WSYNC ; 95 scanlines
                sta WSYNC ; 96 scanlines

                ldy #224
                sty PF2  
                sta WSYNC ; 97 scanlines
                sta WSYNC ; 98 scanlines
                sta WSYNC ; 99 scanlines
                sta WSYNC ; 100 scanlines

                ldy #240
                sty PF2  

                ldx #252
                stx COLUBK
                
                sta WSYNC ; 101 scanlines
                sta WSYNC ; 102 scanlines
                sta WSYNC ; 103 scanlines
                sta WSYNC ; 104 scanlines
                sta WSYNC ; 105 scanlines

                ldy #248
                sty PF2  

                ldx #250
                stx COLUBK

                sta WSYNC ; 106 scanlines
                sta WSYNC ; 107 scanlines
                sta WSYNC ; 108 scanlines
                sta WSYNC ; 109 scanlines
                sta WSYNC ; 110 scanlines

                ldx #42
                stx COLUBK
                    sta WSYNC ; 111 scanlines
                    sta WSYNC ; 112 scanlines

                ldy #252
                sty PF2  

                    sta WSYNC ; 113 scanlines
                    sta WSYNC ; 114 scanlines
                    sta WSYNC ; 115 scanlines
                    sta WSYNC ; 116 scanlines
                    sta WSYNC ; 117 scanlines
                    sta WSYNC ; 118 scanlines
                    sta WSYNC ; 119 scanlines
                    sta WSYNC ; 120 scanlines

                ldx #40
                stx COLUBK
                    sta WSYNC
                    sta WSYNC
                    sta WSYNC
                    sta WSYNC
                    sta WSYNC ; 125 scanlines

                ldy #254
                sty PF2  

                    sta WSYNC
                    sta WSYNC
                    sta WSYNC
                    sta WSYNC
                    sta WSYNC ; 130 scanlines


                ldx #38
                stx COLUBK
                REPEAT 10; 140 scanlines
                    sta WSYNC
                REPEND

                ldy #255
                sty PF2  

                ldx #36
                stx COLUBK
                REPEAT 10; 150 scanlines
                    sta WSYNC
                REPEND
                
              ; horizon
                ldx #32
                stx COLUBK

              ; ready water playfield
                ldy #WHITE_WATER
                sty COLUPF  
                ldy #0
                sty CTRLPF
                sty PF0
                sty PF1
                sty PF2
                sta WSYNC ; 151 scanlines

            ldx #DARK_WATER ;2
            stx COLUBK     ;4

            REPEAT 10; 
             ; flowy water 
                    ldy #0   ;2
                    sty PF0  ;4
                    ldy #3   ;2
                    sty PF1  ;4
                    ldy #255 ;2
                    sty PF2  ;4 - 18 / 22

                    ; delay till 28
                    SLEEP 10

                    ldy #240 ; 2
                    sty PF0 ; 4

                    ; delay till 40
                    SLEEP 6

                    ldy #240 ; 2
                    sty PF1  ; 4

                    ; delay till 50
                    SLEEP 4

                    ldy #0 ; 2
                    sty PF2 ; 4

                    sta WSYNC ; 152 scanlines

                    ldy #0
                    sty PF0
                    sty PF1
                    ldy #254
                    sty PF2

                    ; delay till 84
                    SLEEP 12

                    ldy #240
                    sty PF0

                    ; delay till 116
                    SLEEP 6

                    ldy #252
                    sty PF1

                    ; delay till 195
                    SLEEP 4
                    
                    ldy #0
                    sty PF2

                    sta WSYNC ; 153 scanlines

                REPEND

                ; clear 

                ldx #2
                stx COLUBK
                ldy #0
                sty PF0
                sty PF1
                sty PF2

                REPEAT 20; 191 scanlines
                    sta WSYNC

                ldx #0
                stx COLUBK
 
            lda #%01000010
            sta VBLANK                     ; end of screen - enter blanking

               ; 30 scanlines of overscan...

                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC
                sta WSYNC

            jmp StartOfFrame


            ORG $FFFA

            .word Reset          ; NMI
            .word Reset          ; RESET
            .word Reset          ; IRQ

    	END