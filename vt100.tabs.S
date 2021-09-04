

	rel
	xc
	xc

	use vt.equ


init_tabs	ent


	ldx #80
:loop	stz tabs,x
	dex
	bpl :loop

	lda #72
	ldy #$80
:tloop	tax
	sty tabs,x
	sec
	sbc #8
	bne :tloop

	rts
*:table	db 8*1,8*2,8*3,8*4,8*5,8*6,8*7,8*8*,8*9

set_tab	ent
* input x = x

*	ldx x
	cpx #80
	bge :rts
	lda #$80
	sta tabs,x
:rts	rts

reset_tab ent
* input x = x

*	ldx x
	cpx #80
	bge :rts
	stz tabs,x
:rts	rts


reset_all_tabs ent

	ldx #80-1
:loop	stz tabs,x
	dex
	bpl :loop
	rts	

next_tab_stop ent
* input x = x

*	ldx x
	cpx 79
	bge :80

:loop	bit tabs,x
	bmi :rts
	inx
	cpx #80
	bcc :loop


:80	ldx	#80
:rts	rts


tabs	ds 80

	sav vt100.tabs.L
