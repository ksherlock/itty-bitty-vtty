vt100
	mx %11
	and #$7f
	cmp #' '
	bcs :notctrl
	asl
	tax
	jmp (:ctrl_table,x)
:notctrl
	ldx state
	jmp (:state_table,x)



:state_table
	ext vt52_esc,vt52_dca_1,vt52_dca_2
	ext vt100_esc,vt100_csi,vt100_csi_2
	ext vt100_esc_pound,vt100_esc_lparen,vt100_esc_rparen

	dw char
	dw vt52_esc
	dw vt52_dca_1
	dw vt52_dca_2
	dw char
	dw vt100_esc
	dw vt100_csi
	dw vt100_csi_2
	dw vt100_esc_pound
	dw vt100_esc_lparen
	dw vt100_esc_rparen


:ctrl_table
	dw ctrl_00,ctrl_01,ctrl_02,ctrl_03
	dw ctrl_04,ctrl_05,ctrl_06,ctrl_07
	dw ctrl_08,ctrl_09,ctrl_0a,ctrl_0b
	dw ctrl_0c,ctrl_0d,ctrl_0e,ctrl_0f
	dw ctrl_10,ctrl_11,ctrl_12,ctrl_13
	dw ctrl_14,ctrl_15,ctrl_16,ctrl_17
	dw ctrl_18,ctrl_19,ctrl_1a,ctrl_1b
	dw ctrl_1c,ctrl_1d,ctrl_1e,ctrl_1f



ctrl_00
ctrl_01
ctrl_02
ctrl_03
ctrl_04
ctrl_05 ; answer ENQ
ctrl_06
ctrl_0e ; G1 character set
ctrl_0f ; G0 character set
ctrl_10
ctrl_11 ; XON
ctrl_12
ctrl_13 ; XOFF
ctrl_14
ctrl_15
ctrl_16
ctrl_17
ctrl_19
ctrl_1c
ctrl_1d
ctrl_1e
ctrl_1f
	rts


ctrl_07 ; ring the bell.
	rts

ctrl_1b ; escape -
* vt100 - aborts current escape sequence and starts a new one.
* vt52 - esc esc aborts and starts new 
* vt50 - esc esc aborts
	lda DECANM
	bne :vt52
	lda #st_vt100_esc
	sta state
	rts

:vt52
	lda #st_vt52_esc
	sta state
	rts

ctrl_18
ctrl_1a
* vt100 - abort current escape sequence
* and display error character.
	lda DECANM
	bne :vt52
	lda #st_vt100
	sta state
	rts

:vt52
	lda #st_vt52
	sta state
	rts


ctrl_09 ; tab
* vt100 has adjustable tabs.
	ext tab_table

	ldx x
lp:
	cpx #79
	bcs :rts
	lda tab_table,x
	bne :hit
	inx
	bra :lp

	stx x

	jmp update_cursor
:rts	rts

ctrl_0a ; line feed - cursor down w/ scroll
ctrl_0b ; vertical tab
ctrl_0c ; form feed.

* if LNM is active, equivalent to CR, LF

	lda #LNM
	bne :lnm
	stz x
:lnm

	lda y
	cmp #23
	blt :simple

	lda #" "
	sta cursor_saved_char
	jmp scroll_down

:simple
	inc y
	jmp update_cursor

ctrl_0d ; carriage return - cursor to column 0.
	stz x
	jmp update_cursor
