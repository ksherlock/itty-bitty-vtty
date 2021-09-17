
	lst off
	rel
	xc
	xc

	use vt.equ

	mx %11

init_tabs	ent

	ldx #80-1
:zloop	stz tabs,x
	dex
	bpl :zloop

	lda #$80
	ldy #8
:loop	ldx :table,y
	sta tabs,x
	dey
	bpl :loop

	rts
:table	db 8*1,8*2,8*3,8*4,8*5,8*6,8*7,8*8*,8*9

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
	inx
	cpx #79
	bge :79

:loop	bit tabs,x
	bmi :rts
	inx
	cpx #80
	bcc :loop


:79	ldx	#79
:rts	rts


tabs	ds 80

	sav vt100.tabs.L
