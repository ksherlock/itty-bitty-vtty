

	rel
	xc
	xc

	use vt.equ

vt100_esc ent
* #[()=>cH78DEM
* based on testing, unspecified chars in the 0x20-0x2f range cause it to gobble
* chars until 0x30- terminator (which ends the sequence but does not take an action)

* esc 1 -> hangs? [undocumented]


	ldx #st_vt100
	stx state

	cmp #:MIN
	blt :bad
	cmp #:MAX+1
	bge :rts
	sec
	sbc #:MIN
	asl
	tax
	jmp (:table,x)

:bad
	ldx #st_vt100_esc_bad
	stx state
:rts
	rts

:MIN	equ 35
:MAX	equ 99

:table
	dw :pound	; #
	dw :bad	; $
	dw :bad	; %
	dw :bad	; &
	dw :bad	; '
	dw :lparen	; (
	dw :rparen	; )
	dw :bad	; *
	dw :bad	; +
	dw :bad	; ,
	dw :bad	; -
	dw :bad	; .
	dw :bad	; /
	dw :rts	; 0
	dw :rts	; 1
	dw :rts	; 2
	dw :rts	; 3
	dw :rts	; 4
	dw :rts	; 5
	dw :rts	; 6
	dw esc_7	; 7
	dw esc_8	; 8
	dw :rts	; 9
	dw :rts	; :
	dw :rts	; ;
	dw :rts	; <
	dw esc_eq	; =
	dw esc_gt	; >
	dw :rts	; ?
	dw :rts	; @
	dw :rts	; A
	dw :rts	; B
	dw :rts	; C
	dw esc_D	; D
	dw esc_E ; E
	dw :rts	; F
	dw :rts	; G
	dw esc_H	; H
	dw :rts	; I
	dw :rts	; J
	dw :rts	; K
	dw :rts	; L
	dw esc_M	; M
	dw :rts	; N
	dw :rts	; O
	dw :rts	; P
	dw :rts	; Q
	dw :rts	; R
	dw :rts	; S
	dw :rts	; T
	dw :rts	; U
	dw :rts	; V
	dw :rts	; W
	dw :rts	; X
	dw :rts	; Y
	dw :rts	; Z
	dw :rts	; [
	dw :rts	; \
	dw :rts	; ]
	dw :rts	; ^
	dw :rts	; _
	dw :rts	; `
	dw :rts	; a
	dw :rts	; b
	dw esc_c	; c



:lparen
	ldx #st_vt100_esc_lparen
	stx state
	rts

:rparen
	ldx #st_vt100_esc_rparen
	stx state
	rts

:pound
	ldx #st_vt100_esc_pound
	stx state
	rts


esc_7 ; save cursor position, graphic rendition, and character set.
	rts
esc_8 ; restore cursor position, graphic rendition, and character set.
	rts 

esc_eq ; enter alternate keypad mode
	lda #$80
	sta DECKPAM
	rts
esc_gt ; exit alternate keypad mode
	stz DECKPAM
	rts

esc_H ; set tab stop
	ext set_tab
	ldx x
	jmp set_tab

esc_E ; next line
	stz x
	; drop through
esc_D ; index
	rts

esc_M ; reverse index
	rts

esc_c ; reset terminal.
	rts


vt100_esc_bad ent
	cmp #'0'
	blt :rts
	ldx #st_vt100
	stx state
:rts
	rts


	sav vt100.esc.L
