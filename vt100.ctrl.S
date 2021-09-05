
	lst off
	cas se
	rel
	xc
	xc

	use vt.equ


*control chars
	ext draw_char,update_cursor

control	ent

	asl
	tax
	jmp (:table,x)

:table
	dw :rts	; ^@
	dw :rts	; ^A
	dw :rts	; ^B
	dw :rts	; ^C
	dw :rts	; ^D
	dw enq	; ^E
	dw :rts	; ^F
	dw bel	; ^G
	dw bs	; ^H
	dw tab	; ^I
	dw lf	; ^J
	dw vt	; ^K
	dw ff	; ^L
	dw cr	; ^M
	dw so	; ^N
	dw si	; ^O
	dw :rts	; ^P
	dw xon	; ^Q
	dw :rts	; ^R
	dw xoff	; ^S
	dw :rts	; ^T
	dw :rts	; ^U
	dw :rts	; ^V
	dw :rts	; ^W
	dw can	; ^X
	dw :rts	; ^Y
	dw sub	; ^Z
	dw esc	; ^[
	dw :rts	; ^\
	dw :rts	; ^]
	dw :rts	; ^^
	dw :rts	; ^_

:rts	rts

enq
* send answer back message.
* answer back message is a user-controllable string of text sent as-is
* (with no specific terminator character)
	rts
bel
* todo - trigger nice ensoniq beep.
	rts


bs
* backspace, no wrap
	lda x
	beq :rts
	dec x
	jmp update_cursor
:rts	rts

tab
* go to next tab stop
	rts

lf
vt
ff
* vt and ff interpreted as lf
* LNM: also do cr.
	bit LNM
	bpl :lnm
	stz x
:lnm
	lda y
	cmp BM ; bottom margin
	bne :iny
	jmp scroll_up
:iny	inc y
	jmp update_cursor

cr
	stz x
	jmp update_cursor


so ; G1 character set
si ; G0 character set
	rts

xon
xoff
* flow control...
	rts
can
sub
* cancel esc sequence and display error character
	stz state
	rts

esc
	lda #st_esc
	sta state
	rts