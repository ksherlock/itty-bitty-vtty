
	lst off
	rel
	xc
	xc

	mx %11
	use vt.equ
	use apple2gs.equ
	use debug

	ext scroll_down
	ext recalc_cursor,recalc_cursor_x,recalc_cursor_y
	ext write_modem,read_modem,init_modem,keypress
	ext disable_cursor,enable_cursor,cursor_vector
	ext erase_screen
	ext init_tabs
	ext init_audio

main	debug main

	clc
	xce
	cli

	jsr init
	jsr enable_cursor


	lda #4
	tsb VGCINT ; enable 1-sec interrupt.
	stz SCANINT ; reset 1-sec interrupt



loop
	bit LOCAL
	bmi :kb
	jsr read_modem
	bcc :kb
	pha
	jsr disable_cursor
	pla
	jsr vt100
:kb	
	jsr keypress
	jsr enable_cursor
	bra loop

init
	sta TXTSET
	sta SET80VID
	sta SETALTCHAR
	rep #$30

	ldx #254
:zloop	stz 0,x
	dex
	dex
	bpl :zloop

	lda #$0400
	sta cursor_base
	lda #$01
	sta cursor_base+2

	lda #"  " ; 16-bit
	sta erase_char



	lda #$0080
	sta cursor_state
	sei
	lda cursor_vector
	stal IRQ1SEC
	lda cursor_vector+2
	stal IRQ1SEC+2
	cli

	lda #0 ; clear high byte

	sep #$30

	lda #"_"
	sta cursor_char


	lda #23
	sta DECBM
	lda #$80
	sta LOCAL

	lda #st_vt52
	sta state

	jsr erase_screen
	jsr init_modem
	jsr init_tabs
	jsr init_audio
	rts


dispatch ent
	mx %11
* a = character to xmit
	bit LOCAL
	bmi :local
	jmp write_modem
:local
	pha
	jsr disable_cursor
	pla

* fall through

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
	ext vt52_esc,vt52_dca
	ext vt100_esc,vt100_csi,vt100_csi_2
	ext vt100_esc_pound,vt100_esc_lparen,vt100_esc_rparen
	ext vt100_esc_bad,vt100_csi_bad
	ext draw_char

	dw draw_char
	dw vt52_esc
	dw vt52_dca
	dw draw_char
	dw vt100_esc
	dw vt100_csi
	dw vt100_csi_2
	dw vt100_esc_pound
	dw vt100_esc_lparen
	dw vt100_esc_rparen
	dw vt100_esc_bad
	dw vt100_csi_bad


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
	ext beep
	jmp beep

ctrl_1b ; escape -
* vt100 - aborts current escape sequence and starts a new one.
* vt52 - esc esc aborts and starts new 
* vt50 - esc esc aborts
	bit DECANM
	bpl :vt52
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
* TODO - display error character (mouse text)
	bit DECANM
	bpl :vt52
	lda #st_vt100
	sta state
	rts

:vt52
	lda #st_vt52
	sta state
	rts

ctrl_08 ; back space
	lda x
	beq :rts
	and #$7f
	dec
	sta x
	jmp recalc_cursor_x
:rts	rts

ctrl_09 ; tab
* vt100 has adjustable tabs.
	ext next_tab_stop
	ldx x
	bmi :rts
	jsr next_tab_stop
	stx x
	jmp recalc_cursor_x
:rts rts

ctrl_0a ; line feed - cursor down w/ scroll
ctrl_0b ; vertical tab
ctrl_0c ; form feed.

* if LNM is active, equivalent to CR, LF

	bit #LNM
	bpl :lf
	stz x
	jsr recalc_cursor_x

:lf
	lda y
	cmp DECBM
	bne :simple

*	lda #" " ; needs to factor in reverse video
*	sta cursor_saved_char
	jmp scroll_down
* if LNM mode, need to update cursor as well.

:simple
	cmp #23
	beq :rts
	inc y
	jmp recalc_cursor_y

:rts	rts

ctrl_0d ; carriage return - cursor to column 0.
	stz x
	jmp recalc_cursor_x


	sav vt100.main.L
