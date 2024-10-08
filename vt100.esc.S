
	lst off
	rel
	xc
	xc

	use vt.equ

	mx %11


	ext recalc_cursor,recalc_cursor_x,recalc_cursor_y
	ext scroll_up,scroll_down
	ext reset
	ext update_sgr

vt100_esc ent
* #[()=>cH78DEM
* based on testing, unspecified chars in the 0x20-0x2f range cause it
* to gobble chars until 0x30- terminator (which ends the sequence but
* does not take an action)

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
	dw :bad		; $
	dw :bad		; %
	dw :bad		; &
	dw :bad		; '
	dw :lparen	; (
	dw :rparen	; )
	dw :bad		; *
	dw :bad		; +
	dw :bad		; ,
	dw :bad		; -
	dw :bad		; .
	dw :bad		; /
	dw :rts		; 0
	dw :rts		; 1
	dw :rts		; 2
	dw :rts		; 3
	dw :rts		; 4
	dw :rts		; 5
	dw :rts		; 6
	dw esc_7	; 7
	dw esc_8	; 8
	dw :rts		; 9
	dw :rts		; :
	dw :rts		; ;
	dw :rts		; <
	dw esc_eq	; =
	dw esc_gt	; >
	dw :rts		; ?
	dw :rts		; @
	dw :rts		; A
	dw :rts		; B
	dw :rts		; C
	dw esc_D	; D
	dw esc_E	; E
	dw :rts		; F
	dw :rts		; G
	dw esc_H	; H
	dw :rts		; I
	dw :rts		; J
	dw :rts		; K
	dw :rts		; L
	dw esc_M	; M
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
	dw :csi		; [
	dw :rts		; \
	dw :rts		; ]
	dw :rts		; ^
	dw :rts		; _
	dw :rts		; `
	dw :rts		; a
	dw :rts		; b
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

:csi
	ldx #st_vt100_csi
	stx state
	rts


esc_7 ; save cursor position, graphic rendition, and character set.
* based on testing, DECOM is also saved/restored.
	lda x
	sta saved_x
	lda y
	sta saved_y
	lda DECOM
	sta saved_decom
	lda SGR
	sta saved_sgr

	rts
esc_8 ; restore cursor position, graphic rendition, and character set.

	lda saved_x
	sta x
	lda saved_y
	sta y
	lda saved_decom
	sta DECOM
	lda saved_sgr
	sta SGR

	jsr update_sgr
	jmp recalc_cursor

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
	bmi :rts
	jmp set_tab
:rts	rts

esc_E ; next line
* This sequence causes the active position to move to the first position
* on the next line downward. If the active position is at the bottom
* margin, a scroll up is performed. 
	stz x
	jsr recalc_cursor_x
	; drop through
esc_D ; index
* This sequence causes the active position to move downward one line
* without changing the column position. If the active position is at the
* bottom margin, a scroll up is performed.

	lda y
	cmp DECBM
	beq :scroll
	cmp #23
	beq :rts
	inc y
	jmp recalc_cursor_y

:scroll	jmp scroll_down
:rts	rts


esc_M ; reverse index
* Move the active position to the same horizontal position on the
* preceding line. If the active position is at the top margin, a scroll
* down is performed.

	lda y
	cmp DECTM
	beq :scroll
	cmp #0
	beq :rts
	dec y
	jmp recalc_cursor_y

:scroll	jmp scroll_up
:rts	rts


esc_c ; TODO - reset terminal.
	jmp reset


vt100_esc_bad ent
	cmp #'0'
	blt :rts
	ldx #st_vt100
	stx state
:rts
	rts



vt100_esc_pound ent

* esc # 3 - make line double height (top half)
* esc # 4 - make line double height (bottom half)
* esc # 5 - make line single width, single height
* esc # 6 - make line double width

* esc # 8 - screen alignment - fill screen with E (SGR not honored)
* based on testing, this also resets the scrolling region and homes
* the cursor.

* based on testing, 0+ are term characters, 0x20-0x2f puts it in
* esc_bad state

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

:bad	ldx #st_vt100_esc_bad
	stx state
:rts	rts

:MIN	equ 48
:MAX	equ 57

:table
	dw :rts	; 0
	dw :rts	; 1
	dw :rts	; 2
	dw :rts	; 3
	dw :rts	; 4
	dw :rts	; 5
	dw :rts	; 6
	dw :rts	; 7
	dw :e	; 8
	dw :rts	; 9

:e
* TODO - does this reset DECOM?
	ext fill_screen
	stz x
	stz y
	stz DECTM
	lda #23
	sta DECBM
	jsr recalc_cursor

	lda #"E"
	jmp fill_screen


vt100_esc_lparen ent
vt100_esc_rparen ent

* ( sets G0, ) sets G1
* A - UK set
* B - ASCII set
* 0 - Special Graphics
* 1 - Alternate Char ROM Standard Char Set
* 2 - Alternate Char ROM Special Graphics 

* SO, aka Control-N aka 0x0e set the G1 char set 
* SI, aka Control-O aka 0x0f set the G0 char set

* not currently supported.
* TODO - mouse text support?

	ldx #st_vt100
	stx state

	cmp #'0'
	blt :bad
	rts

:bad	ldx #st_vt100_esc_bad
	stx state
:rts	rts

	sav vt100.esc.L
