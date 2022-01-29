

	lst off
	cas se

	rel
	xc
	xc

	use vt.equ
	use debug

	mx %11

	ext reset_tab,reset_all_tabs
	ext recalc_cursor,recalc_cursor_x,recalc_cursor_y
	ext erase_line_0,erase_line_1,erase_line_2
	ext erase_screen_0,erase_screen_1,erase_screen_2
	ext update_sgr

	ext write_modem,write_modem_str


vt100_csi ent
	debug vt100_csi

* 0123456789;ycnlhgrqJKmABCDHf

* based on testing - 
* everything except '0' - '?' and control chars
* will finish.
* '?' only matters for h/l
*  a misplaced ? (or anything in '0' - '?', except 0-9;)
* will cancel the sequence AFTER it's finished.
* < = > ? are allowed as an initial modifier but only '?' is private
* a mis-placed < = > ? will prevent 0x20-0x2f from terminating the sequence.


	ldx #st_vt100
	stx state

	stz pcount
	stz parms
	stz parms+1 ; some assume 2 parms.
	stz pmod

*	tay ; save for modifier
	cmp #:MIN
	blt :rts
	cmp #:MAX+1
	bge :rts
	sec
	sbc #:MIN
	asl
	tax
	jmp (:table,x)

* 
:rts	rts



:MIN	equ 48
:MAX	equ 121
:table
	dw :digit	; 0
	dw :digit	; 1
	dw :digit	; 2
	dw :digit	; 3
	dw :digit	; 4
	dw :digit	; 5
	dw :digit	; 6
	dw :digit	; 7
	dw :digit	; 8
	dw :digit	; 9
	dw digit	; :
	dw semi
	dw :xmod	; <
	dw :xmod	; =
	dw :xmod	; >
	dw :modifier	; ?
	dw :rts		; @
	dw csi_A	; A
	dw csi_B	; B
	dw csi_C	; C
	dw csi_D	; D
	dw :rts		; E
	dw :rts		; F
	dw :rts		; G
	dw csi_H	; H
	dw :rts		; I
	dw csi_J	; J
	dw csi_K	; K
	dw :rts		; L
	dw :rts		; M
	dw :rts		; N
	dw :rts		; O
	dw :rts		; P
	dw :rts		; Q
	dw :rts		; R
	dw :rts		; S
	dw :rts		; T
	dw :rts		; U
	dw :rts		; V
	dw :rts		; W
	dw :rts		; X
	dw :rts		; Y
	dw :rts		; Z
	dw :rts		; [
	dw :rts		; \
	dw :rts		; ]
	dw :rts		; ^
	dw :rts		; _
	dw :rts		; `
	dw :rts		; a
	dw :rts		; b
	dw csi_c	; c
	dw :rts		; d
	dw :rts		; e
	dw csi_f	; f
	dw csi_g	; g
	dw csi_h	; h
	dw :rts		; i
	dw :rts		; j
	dw :rts		; k
	dw csi_l	; l
	dw csi_m	; m
	dw csi_n	; n
	dw :rts		; o
	dw :rts		; p
	dw csi_q	; q
	dw csi_r	; r
	dw :rts		; s
	dw :rts		; t
	dw :rts		; u
	dw :rts		; v
	dw :rts		; w
	dw :rts		; x
	dw csi_y	; y


:digit
	ldx #st_vt100_csi_2
	stx state

	lsr ; undo asl
	sta parms
	rts
:modifier
	ldx #st_vt100_csi_2
	stx state

	lda #$80
	sta pmod
	rts

:xmod
* ignored.
	ldx #st_vt100_csi_2
	stx state
	rts

vt100_csi_bad ent
	cmp #'@'
	blt :rts
	ldx #st_vt100
	stx state
:rts	rts



vt100_csi_2 ent
	debug vt100_csi_2

	ldx #st_vt100
	stx state

	cmp #:MIN
	blt :rts
	cmp #:MAX+1
	bge :rts
	sec
	sbc #:MIN
	asl
	tax
	jmp (:table,x)

:rts	rts

:MIN	equ 48
:MAX	equ 121
:table
	dw digit	; 0
	dw digit	; 1
	dw digit	; 2
	dw digit	; 3
	dw digit	; 4
	dw digit	; 5
	dw digit	; 6
	dw digit	; 7
	dw digit	; 8
	dw digit	; 9
	dw digit	; :
	dw semi
	dw :modifier	; <
	dw :modifier	; =
	dw :modifier	; >
	dw :modifier	; ?
	dw :rts		; @
	dw csi_A	; A
	dw csi_B	; B
	dw csi_C	; C
	dw csi_D	; D
	dw :rts		; E
	dw :rts		; F
	dw :rts		; G
	dw csi_H	; H
	dw :rts		; I
	dw csi_J	; J
	dw csi_K	; K
	dw :rts		; L
	dw :rts		; M
	dw :rts		; N
	dw :rts		; O
	dw :rts		; P
	dw :rts		; Q
	dw :rts		; R
	dw :rts		; S
	dw :rts		; T
	dw :rts		; U
	dw :rts		; V
	dw :rts		; W
	dw :rts		; X
	dw :rts		; Y
	dw :rts		; Z
	dw :rts		; [
	dw :rts		; \
	dw :rts		; ]
	dw :rts		; ^
	dw :rts		; _
	dw :rts		; `
	dw :rts		; a
	dw :rts		; b
	dw csi_c	; c
	dw :rts		; d
	dw :rts		; e
	dw csi_f	; f
	dw csi_g	; g
	dw csi_h	; h
	dw :rts		; i
	dw :rts		; j
	dw :rts		; k
	dw csi_l	; l
	dw csi_m	; m
	dw csi_n	; n
	dw :rts		; o
	dw :rts		; p
	dw csi_q	; q
	dw csi_r	; r
	dw :rts		; s
	dw :rts		; t
	dw :rts		; u
	dw :rts		; v
	dw :rts		; w
	dw csi_x	; x
	dw csi_y	; y

:modifier
	ldx #st_vt100_csi_bad
	stx state
	rts

semi
	ldx #st_vt100_csi_2
	stx state

	ldx pcount
	cpx #MAX_PCOUNT
	bge :big

	inx
	stx pcount
:big	stz parms,x
:rts	rts

* parameter digit.  clamped to 255 (250+ rounds up to 255)
* in 132 is the largest valid parameter so this is ok.
digit
	ldx #st_vt100_csi_2
	stx state

	lsr ; undo asl
	sta r0
	ldx pcount
	lda parms,x
*	cmp #255
*	beq :rts
	cmp #25
	bge :v

	tay
	lda :mult,y
*	clc ; cleared via cmp
	adc r0
	sta parms,x


:rts
	rts
:v
	lda #$255
	sta parms,x
	rts

:mult	db 0,10,20,30,40,50,60,70,80,90
	db 100,110,120,130,140,150,160,170,180,190
	db 200,210,220,230,240,250



csi_h
	; esc [ ... h (vt100)
	; esc [ ? ... h (private)
	ldy #$80
	bra mode_common

csi_l
	; esc [ ... l (vt100)
	; esc [ ? ... l (private)
	ldy #0

mode_common
	inc pcount
	ldx #0
:loop	lda parms,x
	cmp #:MIN
	blt :next
	cmp #:MAX+1
	bge :next
	phx
	asl
	tax
	jsr (:table,x)
	plx

:next	inx
	cpx pcount
	blt :loop
:rts	rts

:MIN equ 0
:MAX equ 20
:table
	dw :rts ; error
	dw mode_DECCKM
	dw mode_DECANM
	dw :rts ; DECCOLM
	dw :rts ; DECSCLM
	dw mode_DECSCNM
	dw mode_DECOM
	dw mode_DECAWM
	dw mode_DECARM
	dw :rts ; DECINLM
	dw :rts ; 10
	dw :rts ; 11
	dw :rts ; 12
	dw :rts ; 13
	dw :rts ; 14
	dw :rts ; 15
	dw :rts ; 16
	dw :rts ; 17
	dw :rts ; 18
	dw :rts ; 19
	dw mode_LNM
*:mask	dw 0,$40,$40,$40,$40,$40,$40,$40,$40,$40
*	dw 0,0,0,0,0,0,0,0,0,0,0


mode_DECCKM
	bit pmod
	bpl :rts

	sty DECCKM
:rts	rts

mode_DECANM
	bit pmod
	bpl :rts

	sty DECANM
	cpy #0
	bne :rts
* switch to vt52 mode
	ldx #st_vt52
	stx state
:rts	rts


*mode_DECCOLM
*	sty DECCOLM
*	rts


mode_DECSCNM
	bit pmod
	bpl :rts

* todo - invert on-screen characters?
	sty DECSCNM
:rts	rts

mode_DECOM
	bit pmod
	bpl :rts

	sty DECOM
	; move to the new home position
	stz x
	stz y
	cpy #0
	beq :rts
	lda DECTM
	sta y

	phy
	jsr recalc_cursor
	ply

:rts	rts

mode_DECAWM
	bit pmod
	bpl :rts

	sty DECAWM
:rts	rts

mode_DECARM
	bit pmod
	bpl :rts

	sty DECARM
:rts	rts

mode_LNM
	bit pmod
	bmi :rts

	sty LNM
:rts	rts


csi_m
* esc [ ... m
* 0 - attributes off
* 1 - bold
* 4 - underscore
* 5 - blink
* 7 - inverted

	inc pcount
	ldx #0
:loop	lda parms,x
	cmp #8
	bge :next
	tay
	lda SGR
	and :and,y
	ora :or,y
	sta SGR

:next	inx
	cpx pcount
	blt :loop

	jmp update_sgr



:and	db $00,$ff,$ff,$ff,$ff,$ff,$ff,$ff

:or	db %0000_0000,%0000_0010,%0000_0000,%0000_0000
	db %0001_0000,%0010_0000,%0000_0000,%1000_0000



csi_g
* ESC [ g, ESC [ 0 g - clear tab at column
* ESC [ 3 g - clear all tabs

	lda parms
	beq :0
	cmp #3
	beq :3
	rts

:0	ldx x
	jmp reset_tab
:3	jmp reset_all_tabs


p1	mac
	lda parms
	bne ok
	lda #1
ok	sta parms
	<<<

* cursor movement.
* if private mode, no effect.
csi_A
* up

* if cursor is outside the scrolling region, it is not locked to the scrolling region.

	bit pmod
	bmi :rts

	p1

	lda y
	cmp DECTM
	beq :rts
	bcc :simple

	sec
	sbc parms
	bcc :top
	cmp DECTM
*	bcc :top
*	bra :sta
	bcs :sta

:top	lda DECTM
	bra :sta
:rts	rts


:simple
*	lda y
	sec
	sbc parms
*	bcc :0 ; clear indicate underflow.
	bcc :sta
:0	lda #0
:sta	sta y
	jmp recalc_cursor_y

csi_B
* down

	bit pmod
	bmi :rts

	p1

	lda y
	cmp DECBM
	beq :rts
	bge :simple

	clc
	adc parms
	bcs :bottom ; overflow
	cmp DECBM
	bcc :sta

:bottom	lda DECBM
	bra :sta
:rts	rts

:simple
	clc
	adc parms
	bcs :23 ; overflow
	cmp #24
	bcc :sta

:23	lda #23
:sta	sta y
	jmp recalc_cursor_y

csi_C
* right
* in column 80, no effect.

	bit pmod
	bmi :rts

	lda x
	cmp #79
	bcs :rts

	p1
	lda x
*	and #$7f

	clc
	adc parms
	bcs :79 ; overflow
	cmp #80
	bcc :sta

:79	lda #79
:sta	sta x
	jmp recalc_cursor_x
:rts	rts

csi_D 
* left

	bit pmod
	bmi :rts

	p1

	lda x
	and #$7f

	sec
	sbc parms
*	bcc :0 ; underflow
	bcs :sta
:0	lda #0
:sta	sta x
	jmp recalc_cursor_x
:rts	rts


csi_f
csi_H ; direct cursor addressing

	debug csi_H


* honors origin
* large numbers are clamped
* 0 or 1 treated as 1 (1-based counting)

* based on testing, esc [ 253-255 H will position outside the scrolling
* region when DECOM is active (to first 3 lines, respectively)
* this is not emulated.

* y
	lda parms
	beq :yy
	dec
:yy	bit DECOM
	bmi :org
	cmp #23
	blt :yyy
	lda #23
:yyy	sta y
	bra :x	


:org
	clc
	adc DECTM
	cmp DECBM
	blt :org1
	lda DECBM
:org1	sta y

* x
:x
	ldx parms+1
	beq :xx
	dex
:xx
	cpx #79
	blt :xxx
	ldx #79
:xxx	stx x

	jmp recalc_cursor

csi_r ; scrolling region
	debug csi_r
* based on testing
* esc [ n r (no second parmeter) is equivalent to esc [ n ; 24 r
* esc [ r sets scrolling region to 1 ; 24 ( in accordance with above )
* 24 is assumed value for second parameter
* invalid parameters exit without updating 

* based on testing, row parameters are not affected by DECOM.

	lda parms
	beq :p1
	dec parms
:p1

	lda parms+1
	beq :p2
	dec parms+1
	bra :check

:p2	lda #23
	sta parms+1

:check
* 23 max
	ldx parms+0
	cpx #23+1
	bge :rts

	ldx parms+1
	cpx #23+1
	bge :rts


* must be at least 1 line
	lda parms+1
	sec
	sbc parms
	beq :rts
	bmi :rts

* move cursor to origin.
	lda parms
	sta DECTM
	sta y
	lda parms+1
	sta DECBM
	stz x
	bit DECOM
	bmi :j
	stz y
:j	jmp recalc_cursor

:rts	rts

csi_J ; erase screen

	lda parms
	cmp #2+1
	bcs :rts
	asl
	tax
	jmp (:table,x)

:rts	rts

:table
	dw erase_screen_0
	dw erase_screen_1
	dw erase_screen_2

csi_K ; erase line

	lda parms
	cmp #2+1
	bcs :rts
	asl
	tax
	jmp (:table,x)

:rts	rts

:table
	dw erase_line_0
	dw erase_line_1
	dw erase_line_2

csi_q ; LEDs
	rts
csi_n  ; status report

	bit LOCAL
	bmi :rts
	lda parms
	cmp #5
	beq :dsr
	cmp #6
	beq :cpr
:rts	rts
:dsr ; report status
	lda #ESC
	jsr write_modem
	lda #'['
	jsr write_modem
	lda #'0'
	jsr write_modem
	lda #'n'
	jmp write_modem
:cpr ; cursor report
* returned y is in terms of DECOM.
	lda #ESC
	jsr write_modem
	lda #'['
	jsr write_modem

	lda y
	bit DECOM
	bpl :y
	sec
	sbc DECTM

:y	inc
	jsr write_digit
	lda #';'
	jsr write_modem
	lda x
	inc
	jsr write_digit
	lda #'R'
	jmp write_modem


write_digit
* digit must be in the range 1-80
	cmp #10
	bcs :multi
:0	ora #'0'
	jmp write_modem
:multi
	ldx #8
]loop	cmp :table,x
	bcs :ok
	dex
	bra ]loop

:ok	sec
	sbc :table,x
	pha ; save
	txa
	ora #'0'
	jsr write_modem
	pla
	bra :0

:table	db 0,10,20,30,40,50,60,70,80

csi_c  ; what are you?
* DA - Device Attributes

	mx %11

	php
	rep #$10 ; long x/y
	ldy #:response
	jsr write_modem_str
	plp
	rts

:response asc 1b,'[?1;0c',00 ; No options.

csi_y  ; invoke confidence test
* ??? 
	rts



csi_x ; request terminal parameters
* DECREQTPARM – Request Terminal Parameters

	mx %11

	lda parms
	cmp #2
	bcs :rts
	inc
	inc
	ora #'0'
	sta :response+2

	php
	rep #$10 ; long x/y
	ldy #:response
	jsr write_modem_str
	plp
:rts	rts

:response asc 1b,'[x;1;1;112;112;1;0x',00 ; no parity, 8-bits, 9600/9600, 16x multiplier, no stp flags.

	sav vt100.csi.L
