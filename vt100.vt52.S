	lst off

	rel
	xc
	xc
	use vt.equ

	mx %11

*
* vt52 emulation for the vt100
*
* ESC < exits 




	ext write_modem,draw_char
	ext advance_x,recalc_cursor,recalc_cursor_x,recalc_cursor_y


vt52_esc ent
* ABCDFGHIJKYZ<>=


	ldx #st_vt52
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

:rts
	rts


:MIN	equ 60
:MAX	equ 90
:table
	dw esc_lt	; <
	dw esc_eq	; =
	dw esc_gt	; >
	dw :rts		; ?
	dw :rts		; @
	dw esc_A	; A
	dw esc_B	; B
	dw esc_C	; C
	dw esc_D	; D
	dw :rts		; E
	dw esc_F	; F
	dw esc_G	; G
	dw esc_H	; H
	dw esc_I	; I
	dw esc_J	; J
	dw esc_K	; K
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
	dw esc_Y	; Y
	dw esc_Z	; Z



esc_lt
* based on testing, this also resets graphics mode
* (which we don't support anyhow.)
	lda #$80
	sta DECANM
	lda #st_vt100
	sta state
	rts


esc_eq ; enter alternate keypad mode
	lda #$80
	sta DECKPAM
	rts

esc_gt ; exit alternate keypad mode
	stz DECKPAM
	rts

* cursor movement respects the scrolling region.
esc_A ; cursor up.
	lda y
	beq :rts
	cmp DECTM
	beq :rts
	dec y
	jmp recalc_cursor_y

:rts	rts


esc_B ; cursor down
	lda y
	cmp #79
	beq :rts
	cmp DECBM
	beq :rts
	iny y
	jmp recalc_cursor_y

:rts	rts


esc_C ; cursor right

	lda x
	cmp #79
	bcs :rts
	inc x
	jmp recalc_cursor_x
:rts	rts

esc_D ; cursor left

	lda x
	beq :rts
	and #$7f
	dec
	sta x
	jmp recalc_cursor_x
:rts	rts

esc_I ; cursor up w/ line scroll
* based on testing, scrolling only occurs within the
* scroll region.
	rts
esc_J rts
esc_K rts


esc_H ; cursor home
	; based on testing, does not respect scrolling region but does
	; respect origin mode.
	stz x
*	stz y
*	bit DECOM
*	bpl :go
	lda DECTM
	sta y

:go	jmp recalc_cursor


esc_F ; enter graphics mode
*	lda #%0010
*	tsb mode
	rts
esc_G ; exit graphics mode
*	lda #%0010
*	trb mode
	rts

esc_Y ; direct cursor address
* vt100 - does not take effect until the end.
* based on testing, there is internal state information,
* so esc Y a esc B esc Y b is equivalent to esc Y a b
*
* if width exceeded, clamps at right margin.
* if height exceeded, does not change.
	lda #st_vt52_dca
	sta state
	rts

esc_Z ; terminal identity.
	; return ESC / Z
	; based on testing, no display in local mode
	bit LOCAL
	bmi :local
	lda #ESC
	jsr write_modem
	lda #'/'
	jsr write_modem
	lda #'Z'
	jmp write_modem

:local	rts
*	lda #'Z'
*	jmp draw_char



vt52_dca ent
* this differs from esc [ H in that invalid
* values are ignored rather than clamped.
* based on testing, does not respect DECOM.
* based on testing, state is saved if ESC aborts, even
* if switching to vt100 mode and back or ^X to cancel.

	sec
	sbc #' '

	bit :tmp
	bmi :go
	ora #$80
	sta :tmp
	rts

:go	; a = x
	cmp #80
	bge :y
	sta x
:y	lda :tmp
	and #$7f
	cmp #24
	bge :update
	sta y
:update
	stz :tmp
	jmp recalc_cursor


:tmp	ds 2


	sav vt100.vt52.L
