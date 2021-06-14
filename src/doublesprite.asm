; adapted from Eckhard Stolberg's bigmove.asm
; https://www.biglist.com/lists/stella/archives/199803/msg00201.html
; http://www.qotile.net/minidig/tricks.html

	processor 6502

	include vcs.h

; TIA (Stella) write-only registers
;
Vsync		equ	$00
Vblank		equ	$01
Wsync		equ	$02
Rsync		equ	$03
Nusiz0		equ	$04
Nusiz1		equ	$05
Colup0		equ	$06
Colup1		equ	$07
Colupf		equ	$08
Colubk		equ	$09
Ctrlpf		equ	$0A
Refp0		equ	$0B
Refp1		equ	$0C
Pf0             equ     $0D
Pf1             equ     $0E
Pf2             equ     $0F
Resp0		equ	$10
Resp1		equ	$11
Resm0		equ	$12
Resm1		equ	$13
Resbl		equ	$14
Audc0		equ	$15
Audc1		equ	$16
Audf0		equ	$17
Audf1		equ	$18
Audv0		equ	$19
Audv1		equ	$1A
Grp0		equ	$1B
Grp1		equ	$1C
Enam0		equ	$1D
Enam1		equ	$1E
Enabl		equ	$1F
Hmp0		equ	$20
Hmp1		equ	$21
Hmm0		equ	$22
Hmm1		equ	$23
Hmbl		equ	$24
Vdelp0		equ	$25
Vdelp1		equ	$26
Vdelbl		equ	$27
Resmp0		equ	$28
Resmp1		equ	$29
Hmove		equ	$2A
Hmclr		equ	$2B
Cxclr		equ	$2C
;
; TIA (Stella) read-only registers
;
Cxm0p		equ	$00
Cxm1p		equ	$01
Cxp0fb		equ	$02
Cxp1fb		equ	$03
Cxm0fb		equ	$04
Cxm1fb		equ	$05
Cxblpf		equ	$06
Cxppmm		equ	$07
Inpt0		equ	$08
Inpt1		equ	$09
Inpt2		equ	$0A
Inpt3		equ	$0B
Inpt4		equ	$0C
Inpt5		equ	$0D
;
; RAM definitions
; Note: The system RAM maps in at 0080-00FF and also at 0180-01FF. It is
; used for variables and the system stack. The programmer must make sure
; the stack never grows so deep as to overwrite the variables.
;
RamStart	equ	$0080
RamEnd		equ	$00FF
StackBottom	equ	$00FF
StackTop	equ	$0080
;
; 6532 (RIOT) registers
;
Swcha		equ	$0280
Swacnt		equ	$0281
Swchb		equ	$0282
Swbcnt		equ	$0283
Intim		equ	$0284
Tim1t		equ	$0294
Tim8t		equ	$0295
Tim64t		equ	$0296
T1024t		equ	$0297
;
; ROM definitions
;
RomStart        equ     $F000
RomEnd          equ     $FFFF
IntVectors      equ     $FFFA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
s1              EQU     $80
s2              EQU     $82
s3              EQU     $84
s4              EQU     $86
s5              EQU     $88
s6              EQU     $8A
DelayPTR        EQU     $8C
LoopCount       EQU     $8E
TopDelay        EQU     $8F
BottomDelay     EQU     $90
MoveCount       EQU     $91
Temp            EQU     $92
Frame           EQU     $93
s7              EQU     $94
Dir             EQU     $96
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Program initialization
;
		ORG	RomStart

Cart_Init:
		SEI				; Disable interrupts.:
		CLD				; Clear "decimal" mode.

		LDX	#$FF
		TXS				; Clear the stack

Common_Init:
		LDX	#$28		; Clear the TIA registers ($04-$2C)
		LDA	#$00
TIAClear:
		STA	$04,X
		DEX
                BPL     TIAClear        ; loop exits with X=$FF
	
		LDX	#$FF
RAMClear:
		STA	$00,X		; Clear the RAM ($FF-$80)
		DEX
                BMI     RAMClear        ; loop exits with X=$7F
	
		LDX	#$FF
		TXS				; Reset the stack
 
IOClear:
		STA	Swbcnt		; console I/O always set to INPUT
		STA	Swacnt		; set controller I/O to INPUT

DemoInit:       LDA     #$01
                STA     VDELP0
                STA     VDELP1
                LDA     #$03
                STA     Nusiz0
                STA     Nusiz1
                LDA     #$36
                STA     COLUP0
                STA     COLUP1
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
                LDA     #0
                STA     TopDelay
                STA     MoveCount
                STA     Frame
                STA     Dir
                LDA     #179
                STA     BottomDelay
                LDA     #$f2
                STA     DelayPTR+1
                LDA     #$1d+36 ;?????
                STA     DelayPTR
                STA     Wsync
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                STA     RESP0
                STA     RESP1
                LDA     #$50    ;?????
                STA     HMP1
                LDA     #$40    ;?????
                STA     HMP0
                STA     Wsync
                STA     HMOVE
                STA     Wsync
                LDA     #$04
                STA     COLUBK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Main program loop
;
NewScreen:
                LDA     #$02
		STA	Wsync		; Wait for horizontal sync
		STA	Vblank		; Turn on Vblank
                STA	Vsync		; Turn on Vsync
		STA	Wsync		; Leave Vsync on for 3 lines
		STA	Wsync
NewFrame:
                LDA     #16
                BIT     Frame
                BEQ     Frame1
Frame0:                
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
                JMP     EndFrame
Frame1:                
                LDA     #0
                STA     s4
                LDA     #24
                STA     s5
                LDA     #48
                STA     s6
                LDA     #72
                STA     s1
                LDA     #96
                STA     s2
                LDA     #120
                STA     s3
                LDA     #144
EndFrame:
                LDA     Dir
                CMP     #0
                BEQ     EF1
                LDA     s1
                LDX     s3
                STA     s3
                STX     s1

EF1:         
		STA	Wsync
                LDA     #$00
		STA	Vsync		; Turn Vsync off

                LDA     #43             ; Vblank for 37 lines
                                        ; changed from 43 to 53 for 45 lines PAL
		STA	Tim64t		; 43*64intvls=2752=8256colclks=36.2lines

Joystick:       LDA     #$80
                BIT     SWCHA
                BEQ     Right
                LSR
                BIT     SWCHA
                BEQ     Left
Joystick0:
                LSR
                BIT     SWCHA
                BEQ     Down
                LSR
                BIT     SWCHA
                BEQ     UP
                JMP     VblankLoop

UP:
                INC     Frame
                LDA     TopDelay
                BEQ     U1
                DEC     TopDelay
                INC     BottomDelay
U1:             JMP     VblankLoop

Down:
                INC     Frame
                LDA     BottomDelay
                BEQ     D1
                INC     TopDelay
                DEC     BottomDelay
D1:             JMP     VblankLoop

Right:
                INC     Frame
                LDA     #0
                STA     REFP0
                STA     REFP1
                STA     Dir
                LDX     MoveCount
                INX
                STX     MoveCount
                CPX     #3
                BNE     R2
                LDX     DelayPTR
                DEX
                STX     DelayPTR
                CPX     #$1c ;?????
                BNE     R1
                LDA     #$1d ;?????
                STA     DelayPTR
                LDA     #2
                STA     MoveCount
                JMP     Joystick0
R1:             LDA     #0
                STA     MoveCount
R2:             LDA     #$f0
                STA     HMP0
                STA     HMP1
                STA     Wsync
                STA     HMOVE
                JMP     Joystick0

Left:
                INC     Frame
                LDA     #8
                STA     REFP0
                STA     REFP1
                STA     Dir
                LDX     MoveCount
                DEX
                STX     MoveCount
                CPX     #$ff
                BNE     L2
                LDX     DelayPTR
                INX
                STX     DelayPTR
                CPX     #$1d+37 ;?????
                BNE     L1
                LDA     #$1d+36 ;#?????
                STA     DelayPTR
                LDA     #0
                STA     MoveCount
                JMP     Joystick0
L1:             LDA     #2
                STA     MoveCount
L2:             LDA     #$10
                STA     HMP0
                STA     HMP1
                STA     Wsync
                STA     HMOVE
                JMP     Joystick0

                ORG     $F200
VblankLoop:
		LDA	Intim
		BNE	VblankLoop	; wait for vblank timer
		STA	Wsync		; finish waiting for the current line
		STA	Vblank		; Turn off Vblank

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ScreenStart:

                LDY     TopDelay
                INY     ;?????
        
X1:             STA     Wsync
                DEY               ;2
                BNE     X1        ;2+1
                LDY     #4 ;????? ;2
X2:             DEY               ;2
                BPL     X2        ;2+1
                LDA     #23       ;2
                STA     LoopCount  ;3
                JMP     (DelayPTR) ;5
JNDelay:        byte      $c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9
                byte      $c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9
                byte      $c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9
                byte      $c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c5
                NOP                 ;2
X3:             NOP                 ;2 2
                NOP                 ;2 4
                NOP                 ;2 6
                LDY     LoopCount   ;3 9
                LDA     (s1),Y      ;5 14
                STA     GRP0        ;3 17
                LDA     (s2),Y      ;5 22
                STA     GRP1        ;3 25
                LDA     (s3),Y      ;5 30
                STA     GRP0        ;3 33
                LDA     (s3),Y      ;5 35
                STA     Temp        ;3 38
                LDA     (s2),Y      ;5 43
                TAX                 ;2 45
                LDA     (s1),Y      ;5 50
                LDY     Temp        ;3 53
                STA     GRP1        ;3 56
                STX     GRP0        ;3 59
                STY     GRP1        ;3 62
                STA     GRP0        ;3 65 ; -- useless?
                DEC     LoopCount   ;5 70
                BPL     X3          ;2+1 72+1
                LDA     #0
                STA     GRP0
                STA     GRP1
                STA     GRP0
                STA     GRP1
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                LDY     BottomDelay
                INY     ;?????
X4:             STA     Wsync
                DEY
                BNE     X4
                LDA     #$02
                STA     Vblank
                STA     Wsync
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OverscanStart:  LDA     #35             ;skip 30 lines (overscan)
		STA	Tim64t

OverscanLoop:
		LDA	Intim
		BNE	OverscanLoop	; wait for Overscan timer
		STA	Wsync		; finish waiting for the current line


                JMP     NewScreen

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                ORG     $FF00
Data:
                byte	$0,$1,$2,$4,$b,$e,$f,$1f,$1f,$1f,$3f,$7f,$df,$87,$1,$0,$1,$2,$1,$2,$4,$8,$0,$0; 24
                byte	$0,$0,$46,$81,$3,$6,$7e,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$f3,$fd,$f0,$f8,$3c,$1c,$1e,$c,$12,$12; 24
                byte	$0,$0,$80,$40,$21,$62,$c4,$88,$10,$a0,$c0,$b0,$c8,$e6,$fe,$fc,$f8,$70,$20,$0,$0,$0,$0,$0; 24
                byte	$0,$84,$48,$28,$34,$1e,$1f,$f,$1f,$1f,$7f,$ff,$9f,$f,$1,$0,$2,$1,$1,$2,$4,$8,$0,$0; 24
                byte	$0,$0,$0,$0,$0,$1,$3d,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$f3,$fc,$f0,$f8,$3c,$1c,$1e,$c,$12,$12; 24
                byte	$0,$20,$48,$48,$91,$92,$24,$e8,$d0,$a0,$c0,$c0,$fc,$e3,$ff,$fe,$7c,$38,$10,$0,$0,$0,$0,$0; 24
		byte	$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0; 24

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Set up the 6502 interrupt vector table
;
		ORG	IntVectors
NMI             word      Cart_Init
Reset           word      Cart_Init
IRQ             word      Cart_Init
        
		END
