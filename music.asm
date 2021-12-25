; https://www.ibiblio.org/mutopia/ftp/SchubertF/D881B/SchubertF-D881B-Fischerweise/SchubertF-D881B-Fischerweise-let.pdf
;    a  220.0000
;    b  246.9417
; do c  261.6256
;    c# 277.1826
; re d  293.6648
;    d# 311.1270
; me e  329.6276
; fa f  349.2282
;    f# 369.9944
; so g  391.9954
; la a  440.0000
; ti b  493.8833
; do c  523.2511
;    c# 554.3653
; re d  587.3295
; mi e  659.2551
;
; 220.0, 246.9417, 261.6256, 277.1826, 293.6648, 311.1270, 329.6276, 349.2282, 369.9944, 391.9954, 440.0000, 493.8833, 523.2511, 554.3653, 587.3295, 659.2551
; [31, 28, 26, 25, 23, 22, 21, 20, 18, 17, 15, 14, 13, 12, 11, 10]

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
WHITE = $0f
BLACK = 0
#else
; PAL Colors
WHITE = $0E
BLACK = 0
#endif

TRACK_LENGTH = TRACK_0_END - TRACK_0_START
BEATS_PER_MINUTE = 224
TICKS_PER_BEAT = (60 * 60) / BEATS_PER_MINUTE

CLICK_AUDC = 0
SAW_AUDC = 1
BASS_AUDC = 6
NOISE_AUDC = 8
LEAD_AUDC = 12
BUZZ_AUDC = 15

VOLUME = 10
; C4 = 23
; D4 = 20
; E4 = 18
; F4 = 17
; G4 = 15
; A4 = 14
; B4 = 12
; C5 = 11
; D5 = 10
; E5 = 9

A3  = 31
B3  = 28
C4  = 26
CS4 = 25
D4  = 23
DS4 = 22
E4  = 21
F4  = 20
FS4 = 18
G4  = 17
A4  = 15
B4  = 14
C5  = 13
CS5 = 12
D5  = 11
E5  = 10

KICK  = 30
SNARE = 6

; ----------------------------------
; variables

  SEG.U variables

    ORG $80

metronome           ds 1
volume              ds 2
sustain             ds 2
decay               ds 2
track_ptr           ds 1

    SEG

; ----------------------------------
; code

  SEG
    ORG $F000

Reset

    ; do the clean start macro
            CLEAN_START

            ; lda NOISE_AUDC
            ; sta AUDC0
            lda LEAD_AUDC
            sta AUDC0
            lda LEAD_AUDC
            sta AUDC1

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

tracker_start
            dec metronome
            bpl tracker_adsr
            ldx #TICKS_PER_BEAT
            stx metronome
            ldx track_ptr

tracker_start_0
            lda TRACK_0_START,x
            beq tracker_rest_0
            sta AUDF0
            lda #TICKS_PER_BEAT 
            sta sustain
            lda #1
            sta decay
            lda #VOLUME
tracker_rest_0            
            sta volume
            sta AUDV0

tracker_start_1
            lda TRACK_1_START,x
            beq tracker_rest_1
            sta AUDF1
            lda #TICKS_PER_BEAT / 2
            sta sustain+1
            lda #1
            sta decay+1
            lda #VOLUME / 2
tracker_rest_1     
            sta AUDV1
            sta volume+1

            inx
            cpx #<TRACK_LENGTH
            bmi tracker_save
            ldx #0
tracker_save
            stx track_ptr
tracker_adsr
tracker_adsr_0
            dec sustain
            bpl tracker_adsr_1
            lda volume 
            sec
            sbc decay
            bpl tracker_volume_0
            lda #0
tracker_volume_0
            sta volume
            sta AUDV0
tracker_adsr_1
            dec sustain + 1
            bpl tracker_end
            lda volume + 1
            sec
            sbc decay + 1
            bpl tracker_volume_1
            lda #0
tracker_volume_1
            sta volume+1
            sta AUDV1
tracker_end

waitOnVBlank            
            cpx INTIM
            bmi waitOnVBlank

;--------------------
; Screen start

            ldx #192
waitOnScreen
            sta WSYNC
            dex
            bne waitOnScreen


;--------------------
; Overscan start

            ldx #30
waitOnOverscan
            sta WSYNC
            dex
            bne waitOnOverscan

            jmp newFrame

    ORG $FE00

TRACK_0_START
    .byte FS4,G4,A4,0,A4,G4,FS4,0,E4,FS4,G4,G4,G4,0,E4,0,E4,FS4
    .byte G4,0,G4,A4,B4,0,FS4,0,G4,G4,G4,G4,0,0,G4,A4,B4,0,A4,0,G4,0,FS4,0
    .byte FS4,FS4,FS4,0,E4,0,A4,0,A4,0,G4,FS4,E4,0,A4,0,FS4,FS4,FS4,FS4,0,0,FS4,G4
    .byte A4,0,G4,FS4,E4,0,A4,0,D4,D4,D4,D4,0,0,0,0
TRACK_0_END
TRACK_1_START
    .byte D4,E4,FS4,A3,FS4,E4,D4,A3,CS4,D4,E4,A3,E4,A3,CS4,A3,E4,FS4
    .byte E4,B3,E4,FS4,G4,B3,DS4,B3,E4,B3,E4,DS4,E4,B3,E4,FS4,G4,B3,FS4,B3,E4,B3,D4,B3
    .byte D4,A3,D4,A3,CS4,A3,CS4,A3,D4,A3,D4,FS4,D4,A3,CS4,A3,FS4,A3,FS4,G4,A4,A3,D4,D4
    .byte D4,A3,D4,FS4,D4,A3,CS4,A3,D4,A3,FS4,G4,A4,A3,G4,A4
TRACK_1_END

TRACK_2_START
    .byte KICK,0,0,SNARE,0,0,KICK,0,0,0,SNARE,0,KICK,0,0          
TRACK_2_END

    ORG $FFFA

    .word Reset          ; NMI
    .word Reset          ; RESET
    .word Reset          ; IRQ

    END