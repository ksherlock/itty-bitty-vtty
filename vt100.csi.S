

	lst off
	cas se

	rel
	xc
	xc

	use vt.equ

	ext update_cursor,reset_tab,reset_all_tabs

vt100_csi ent
* 0123456789;ycnlhgrqJKmABCDHf

* based on testing - 
* everything except '0' - '?' and control chars
* will finish.
* '?' only matters for h/l
*  a misplaced ? (or anything in '0' - '?', except 0-9;)
* will cancel the sequence AFTER it's finished.
* < = > ? are allowed as an initial modifier but only '?' is private
* a mis-placed < = > ? will prevent 0x20-0x2f from terminating the sequence.


	inc state
	inc state

	stz pcount
	stz parms
	stz parms+1 ; some assume 2 parms.
	stz pmod

*	tay ; save for modifier
	cmp #:MIN
	blt :end
	cmp #:MAX+1
	bge :end
	sec
	sbc #:MIN
	asl
	tax
	jmp (:table,x)

* 
:end
	ldx #st_vt100
	stx state
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
	dw :rts		; <
	dw :rts		; =
	dw :rts		; >
	dw :modifier	; ?
	dw :end		; @
	dw csi_A	; A
	dw csi_B	; B
	dw csi_C	; C
	dw csi_D	; D
	dw :end		; E
	dw :end		; F
	dw :end		; G
	dw csi_H	; H
	dw :end		; I
	dw csi_J	; J
	dw csi_K	; K
	dw :end		; L
	dw :end		; M
	dw :end		; N
	dw :end		; O
	dw :end		; P
	dw :end		; Q
	dw :end		; R
	dw :end		; S
	dw :end		; T
	dw :end		; U
	dw :end		; V
	dw :end		; W
	dw :end		; X
	dw :end		; Y
	dw :end		; Z
	dw :end		; [
	dw :end		; \
	dw :end		; ]
	dw :end		; ^
	dw :end		; _
	dw :end		; `
	dw :end		; a
	dw :end		; b
	dw csi_c	; c
	dw :end		; d
	dw :end		; e
	dw csi_f	; f
	dw csi_g	; g
	dw csi_h	; h
	dw :end		; i
	dw :end		; j
	dw :end		; k
	dw csi_l	; l
	dw csi_m	; m
	dw csi_n	; n
	dw :end		; o
	dw :end		; p
	dw csi_q	; q
	dw csi_r	; r
	dw :end		; s
	dw :end		; t
	dw :end		; u
	dw :end		; v
	dw :end		; w
	dw :end		; x
	dw csi_y	; y


:digit
	lsr ; undo asl
	sta parms
	rts
:modifier
	lda #$80
	sta pmod
	rts


vt100_csi_bad ent
	cmp #'@'
	blt :rts
	ldx #st_vt100
	stx state
:rts	rts



vt100_csi_2 ent

	cmp #:MIN
	blt :end
	cmp #:MAX+1
	bge :end
	sec
	sbc #:MIN
	jmp (:table,x)

:badmod
	cmp #'@'
	blt :rts

:end
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
	dw :end		; @
	dw csi_A	; A
	dw csi_B	; B
	dw csi_C	; C
	dw csi_D	; D
	dw :end		; E
	dw :end		; F
	dw :end		; G
	dw csi_H	; H
	dw :end		; I
	dw csi_J	; J
	dw csi_K	; K
	dw :end		; L
	dw :end		; M
	dw :end		; N
	dw :end		; O
	dw :end		; P
	dw :end		; Q
	dw :end		; R
	dw :end		; S
	dw :end		; T
	dw :end		; U
	dw :end		; V
	dw :end		; W
	dw :end		; X
	dw :end		; Y
	dw :end		; Z
	dw :end		; [
	dw :end		; \
	dw :end		; ]
	dw :end		; ^
	dw :end		; _
	dw :end		; `
	dw :end		; a
	dw :end		; b
	dw csi_c	; c
	dw :end		; d
	dw :end		; e
	dw csi_f	; f
	dw csi_g	; g
	dw csi_h	; h
	dw :end		; i
	dw :end		; j
	dw :end		; k
	dw csi_l	; l
	dw csi_m	; m
	dw csi_n	; n
	dw :end		; o
	dw :end		; p
	dw csi_q	; q
	dw csi_r	; r
	dw :end		; s
	dw :end		; t
	dw :end		; u
	dw :end		; v
	dw :end		; w
	dw :end		; x
	dw csi_y	; y

:modifier
	ldx #st_vt100_csi_bad
	stx state
	rts

semi
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

:mult	da 0,10,20,30,40,50,60,70,80,90
	da 100,110,120,130,140,150,160,170,180,190
	da 200,210,220,230,240,250



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
	lda #DECTM
	sta y

	phy
	jsr update_cursor
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
:rts	rts


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


* cursor movement.
csi_A
csi_B
csi_C
csi_D 
	rts

csi_f
csi_H ; direct cursor addressing
	rts

csi_r ; scrolling region
	rts

csi_J ; erase
	rts
csi_K ; erase
	rts

csi_q ; LEDs
	rts
csi_n  ; status report
csi_c  ; what are you?
csi_y  ; invoke confidence test
	rts

	sav vt100.csi.L
