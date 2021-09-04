


	rel
	xc
	xc

	use vt.equ


vt100_csi ent
	inc state
	inc state

	stz pcount
	stz parms
	stz parms+1 ; some assume 2 parms.
	stz pmod

	tay ; save for modifier
	cmp #:MIN
	blt :bad
	cmp #:MAX+1
	bge :bad
	sec
	sbc #:MIN
	asl
	tax
	jmp (:table,x)
:bad
	ldx #st_vt100
	stx state
:rts	rts

:table

* 0123456789;ycnlhgrqJKmABCDHf

* based on testing - 
* everything except '0' - '?' and control chars
* will finish.
* '?' only matters for h/l
*  a misplaced ? (or anything in '0' - '?', except 0-9;)
* will cancel the sequence AFTER it's finished.
* < = > ? are allowed as an initial modifier but only '?' is private
* a mis-placed < = > ? will prevent 0x20-0x2f from terminating the sequence.

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
	dw :rts	; <
	dw :rts	; =
	dw :rts	; >
	dw :modifier	; ?
	dw $0	; @
	dw $0	; A
	dw $0	; B
	dw $0	; C
	dw $0	; D
	dw $0	; E
	dw $0	; F
	dw $0	; G
	dw $0	; H
	dw $0	; I
	dw $0	; J
	dw $0	; K
	dw $0	; L
	dw $0	; M
	dw $0	; N
	dw $0	; O
	dw $0	; P
	dw $0	; Q
	dw $0	; R
	dw $0	; S
	dw $0	; T
	dw $0	; U
	dw $0	; V
	dw $0	; W
	dw $0	; X
	dw $0	; Y
	dw $0	; Z
	dw $0	; [
	dw $0	; \
	dw $0	; ]
	dw $0	; ^
	dw $0	; _
	dw $0	; `
	dw $0	; a
	dw $0	; b
	dw $0	; c
	dw $0	; d
	dw $0	; e
	dw $0	; f
	dw $0	; g
	dw $0	; h
	dw $0	; i
	dw $0	; j
	dw $0	; k
	dw $0	; l
	dw $0	; m
	dw $0	; n
	dw $0	; o
	dw $0	; p
	dw $0	; q
	dw $0	; r
	dw $0	; s
	dw $0	; t
	dw $0	; u
	dw $0	; v
	dw $0	; w
	dw $0	; x
	dw $0	; y


:digit
	lsr ; undo asl
	sta parms
	rts
:modifier
	ldx #$40 ; bit -> v
	stx pmod
	rts


vt100_csi_2 ent

	; if < '0' and invalid modifier, don't terminate.
	bit pmod
	bmi :badmod
	cmp #'@'
	blt :0
	ldx #st_vt100
	stx state

:0	cmp #:MIN
	blt :bad
	cmp #:MAX+1
	bge :bad
	sec
	sbc #:MIN
	jmp (:table,x)

:badmod
	cmp #'@'
	blt :rts

:bad
	ldx #st_vt100
	stx state
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

:modifier
	lda #$80
	sta pmod
	rts

semi
	ldx pcount
	cpx #MAX_PCOUNT
	bge :rts

	inx
	stx pcount
	stz parms,x
:rts	rts

* parameter digit.  clamped to 255 (250+ rounds up to 255)
* in 132 is the largest valid parameter so this is ok.
digit
	lsr ; undo asl
	sta r0
	ldx pcount
	lda parms,x
*	cmp #255
*	beq :rts
	cmp #25
	bge :v

	tay
	lda :table,y
*	clc ; cleared via cmp
	adc r1
	sta parms,x


:rts
	rts
:v
	lda #$255
	sta parms,x
	rts

:table	da 0,10,20,30,40,50,60,70,80,90
	da 100,110,120,130,140,150,160,170,180,190
	da 200,210,220,230,240,250





set_mode
	; esc [ ... h (vt100)
	; esc [ ? ... h (private)
	ldy #$80
	bra mode_common

reset_mode
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
	bgt :next
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
	bvc :rts

	sty DECCKM
:rts	rts

mode_DECANM
	bit pmod
	bvc :rts

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
	bvc :rts

* todo - invert on-screen characters?
	sty DECSCNM
:rts	rts

mode_DECOM
	bit pmod
	bvc :rts

	sty DECOM
	; move to the new home position
	stz x
	stz y
	cpy #0
	beq :rts
	lda #DECTM
	sta y

	phy
	jsr update_cursor
	ply

:rts	rts

mode_DECAWM
	bit pmod
	bvc :rts

	sty DECAWM
:rts	rts

mode_DECARM
	bit pmod
	bvc :rts

	sty DECARM
:rts	rts

mode_LNM
	bit pmod
	bvs :rts

	sty LNM
:rts	rts


char_attr
* esc [ ... m
	inc pcount
	ldx #0
:loop	lda parms,x
	cmp #8
	bge :next
	tay
	lda SGR
	and :and,y
	ora :or,y
	lda :table,y
	sta SGR

:next	inx
	cpx pcount
	blt :loop
:rts	rts


:and	db $00,$ff,$ff,$ff,$ff,$ff,$ff,$ff

:or	db %0000_0000,%0000_0010,%0000_0000,%0000_0000
	db %0001_0000,%0010_0000,%0000_0000,%1000_0000



reset_tab
* ESC H - set tab at current column [vt100.s]
* ESC [ g, ESC [ 0 g - clear tab at column
* ESC [ 3 g - clear all tabs

	lda parm
	beq :0
	cmp #3
	beq :3
	rts
:0
	ldx x
	stz tabs,x
	rts
:3
	ldx #80-1
:loop	stz tabs,x
	dex
	bpl :loop
	rts

	sav vt100.csi.L
