
	lst off

	rel
	xc
	xc
	use vt.equ
	use apple2gs.equ

	mx %11


* x 0-79
* y 0-23
* DECMT 0-22
* DECMB 1-23
* 
* cursor_base - pointer to current line
* cursor_offset - index into current line
* cursor_saved_char - saved character under the cursor
* cursor_state - $80 = disabled, $40 = on



text
	dw $0400
	dw $0480
	dw $0500
	dw $0580
	dw $0600
	dw $0680
	dw $0700
	dw $0780
	dw $0428
	dw $04a8
	dw $0528
	dw $05a8
	dw $0628
	dw $06a8
	dw $0728
	dw $07a8
	dw $0450
	dw $04d0
	dw $0550
	dw $05d0
	dw $0650
	dw $06d0
	dw $0750
	dw $07d0



disable_cursor ent
	mx %11
	php
	sei
	bit cursor_state
	bmi :rts
	bvc :80

	lda cursor_saved_char
	ldy cursor_offset
	sta [cursor_base],y

:80	lda #$80
	tsb cursor_state

:rts	plp
	rts

enable_cursor ent
	mx %11
	php
	sei
	bit cursor_state
	bpl :rts
	bvc :80

* option for inverted cursor?
	ldy cursor_offset
	lda [cursor_base],y
	sta cursor_saved_char
	lda cursor_char
	sta [cursor_base],y

:80	lda #$80
	trb cursor_state

:rts	plp
	rts


cursor_vector	ent
	jml cursor_int

NumInts	equ $e01d67

cursor_int
* cursor interrupt - blink the cursor.

	mx %11

	phb
	phd
	phk
	plb


* check if CDA active.
* $ff = inactive, $00 = active
	lda >NumInts
	bpl :rts

	pea DPAGE
	pld

	ldy cursor_offset

	lda cursor_state
	bmi :rts
	eor #$40
	sta cursor_state
	beq :off
:on
	lda [cursor_base],y
	sta cursor_saved_char
	lda cursor_char
	sta [cursor_base],y

	bra :rts

:off
	lda cursor_saved_char
	sta [cursor_base],y

:rts	stz SCANINT ; reset 1-sec interrupt
	pld
	plb
	clc
	rtl




recalc_cursor ent
* recalculate the cursor pointer after x/y changed
* assumes cursor is off so no saving/restoring the cursor char.
	mx %11
	php
	rep #$30
	lda y
	asl
	tay
	lda text,y
	sta cursor_base

	lda x
	and #$7f
	lsr
	sta cursor_offset
	stz cursor_base+2
	bcs :ok
	inc cursor_base+2

:ok	plp
	rts

recalc_cursor_x ent

	mx %11
	php

	lda x
	and #$7f
	lsr
	sta cursor_offset
	stz cursor_base+2
	bcs :ok
	inc cursor_base+2

:ok	plp
	rts
	

recalc_cursor_y ent

	mx %11
	php
	rep #$30

	lda y
	asl
	tay
	lda text,y
	sta cursor_base
	plp
	rts


advance_x ent
	mx %11

*	ldx x
*	cpx #79
*	bcs :rts

	inc x

	lda #1
	eor cursor_base+2
	sta cursor_base+2

	beq :rts

	inc cursor_offset

:rts	rts



draw_char ent
	; a = char

* alternate character set
* 00 - 1f = uppercase inverse letters ('@' - '_')
* 00 - 3f = special characters, inverse (' ' - '?')
* 40 - 4f = mouse text 
* 60 - 7f = lower case letters, inverse
* 80 - 9f = upper case letters, normal
* a9 - ff = special, upper, lower chars, normal.

* for normal letters, ora $80
* for inverse letters, uppercase need to be remapped to 0-1f
* others don't change.
	bit draw_inverse
	bpl :normal
; invert it.
	cmp #$60 ; `, first lowercase
	bge draw_char_raw ; nothing to do for lowercase
	cmp #$40 ; @, first uppercase
	bcc draw_char_raw ; nothing to do for special

:uc	and #%10111111 ; ~ $40
	bra draw_char_raw


:normal	ora #$80

draw_char_raw ent
* entry point for writing character to screen w/o processing it


*	sta cursor_saved_char

* with DECAWM, x = 79, will CR LF (with scroll) before drawing character.

* at column 79, x increases but cursor does not.  up/down does not change
* overflow.  backspace / left arrow will go to 78.

* x = 80 indicates next char will wrap if DECAWM. however, treated as 79 

* based on testing, will not advance to column 80 unless DECAWM is enabled.

	ldx x
	cpx #79
	bcs :rm

	ldy cursor_offset
	sta [cursor_base],y
	jmp advance_x


:rm
	beq :79

	bit DECAWM
	bmi :wrap

:79
	ldy cursor_offset
	sta [cursor_base],y
	lda DECAWM ; set bit 7 if DECAWM.
	tsb x ; mark overflow
	rts


:wrap
	stz x
	ldy y
	cpy DECBM
	beq :scroll
	cpy #23
	beq :23 ; 

	inc y
:23	pha ; save character
	jsr recalc_cursor
	pla
	sta [cursor_base] ; offset 0
	rts

:scroll
	pha ; save

	jsr scroll_down
	jsr recalc_cursor_x
	pla
	sta [cursor_base] ; offset 0
	rts	


* erase screen commands are not affected by origin or scrolling region.

erase_screen ent
erase_screen_2 ent
* erase the entire screen.

	mx %11
	lda erase_char
* fall through
fill_screen ent
* fill the entire screen with the a register.
* text screen is out of order, so this doesn't use much code but
* it's not linear either.
* +64 bytes of screen hole data.
	mx %11

	sta >$000400
	sta >$010400

	php
	rep #$30


	ldx #$0400
	ldy #$0401
	lda #40*3-2
	mvn $010000,$010000

	ldx #$0400
	ldy #$0480
	lda #40*3-1
	mvn $010000,$010000

	ldx #$0400
	ldy #$0500
	lda #40*3-1
	mvn $010000,$010000

	ldx #$0400
	ldy #$0580
	lda #40*3-1
	mvn $010000,$010000

	ldx #$0400
	ldy #$0600
	lda #40*3-1
	mvn $010000,$010000

	ldx #$0400
	ldy #$0680
	lda #40*3-1
	mvn $010000,$010000

	ldx #$0400
	ldy #$0700
	lda #40*3-1
	mvn $010000,$010000

	ldx #$0400
	ldy #$0780
	lda #40*3-1
	mvn $010000,$010000

* 
	ldx #$0400
	ldy #$0401
	lda #40*3-2
	mvn $000000,$000000

	ldx #$0400
	ldy #$0480
	lda #40*3-1
	mvn $000000,$000000

	ldx #$0400
	ldy #$0500
	lda #40*3-1
	mvn $000000,$000000

	ldx #$0400
	ldy #$0580
	lda #40*3-1
	mvn $000000,$000000

	ldx #$0400
	ldy #$0600
	lda #40*3-1
	mvn $000000,$000000

	ldx #$0400
	ldy #$0680
	lda #40*3-1
	mvn $000000,$000000

	ldx #$0400
	ldy #$0700
	lda #40*3-1
	mvn $000000,$000000

	ldx #$0400
	ldy #$0780
	lda #40*3-1
	mvn $000000,$000000




* not needed since $0,$0 last
*	phk
*	plb
	plp
	rts

* scroll...
* scroll will always be one line at a time
scroll_up ent
* move DECTM .. DECBM-1 -> DECTM+1 .. DECBM insert blank line at DECTM.

	mx %11
	php
	rep #$30


	lda DECBM
	sec
	sbc DECTM
	sta r0

	lda DECBM
	asl ;
	tax
	jmp (:dispatch,x)


:dispatch
	dw :00,:01,:02,:03,:04
	dw :05,:06,:07,:08,:09
	dw :10,:11,:12,:13,:14
	dw :15,:16,:17,:18,:19
	dw :20,:21,:22,:23



* mvn 1,1 first so mvn 0,0 will restore b
:cp	mac
	lda #40-1
	ldx #]1
	ldy #]2
	mvn $010000,$010000

	lda #40-1
	ldx #]1
	ldy #]2
	mvn $000000,$000000

	dec r0
	bne *+5
	brl :done
	<<<

* number refers to the source line.
:23	:cp $0750;$07d0
:22	:cp $06d0;$0750
:21	:cp $0650;$06d0
:20	:cp $05d0;$0650
:19	:cp $0550;$05d0
:18	:cp $04d0;$0550
:17	:cp $0450;$04d0
:16	:cp $07a8;$0450
:15	:cp $0728;$07a8
:14	:cp $06a8;$0728
:13	:cp $0628;$06a8
:12	:cp $05a8;$0628
:11	:cp $0528;$05a8
:10	:cp $04a8;$0528
:09	:cp $0428;$04a8
:08	:cp $0780;$0428
:07	:cp $0700;$0780
:06	:cp $0680;$0700
:05	:cp $0600;$0680
:04	:cp $0580;$0600
:03	:cp $0500;$0580
:02	:cp $0480;$0500
:01	:cp $0400;$0480
:00

:done
* now clear DECTM line
*	lda DECTM
*	asl
*	tay
*	ldx text,y

	ldx cursor_base
	lda erase_char
	sta cursor_saved_char
	ldy #19
:loop
	sta >$000000,x
	sta >$010000,x
	inx
	inx
	dey
	bpl :loop

	plp
	rts


scroll_down ent
* move DECTM+1 .. DECBM -> DECTM .. DECBM-1, insert blank line at DECBM.

	mx %11
	php
	rep #$30


	lda DECBM
	sec
	sbc DECTM
	sta r0

	lda DECTM
	asl ;
	tax
	jmp (:dispatch,x)


:dispatch
	dw :00,:01,:02,:03,:04
	dw :05,:06,:07,:08,:09
	dw :10,:11,:12,:13,:14
	dw :15,:16,:17,:18,:19
	dw :20,:21,:22,:23


:cp	mac
	lda #40-1
	ldx #]1
	ldy #]2
	mvn $010000,$010000

	lda #40-1
	ldx #]1
	ldy #]2
	mvn $000000,$000000

	dec r0
	bne *+5
	brl :done
	<<<

* todo -- fix offsets

* number refers to the dest line.
:00	:cp $0480;$0400
:01	:cp $0500;$0480
:02	:cp $0580;$0500
:03	:cp $0600;$0580
:04	:cp $0680;$0600
:05	:cp $0700;$0680
:06	:cp $0780;$0700
:07	:cp $0428;$0780
:08	:cp $04a8;$0428
:09	:cp $0528;$04a8
:10	:cp $05a8;$0528
:11	:cp $0628;$05a8
:12	:cp $06a8;$0628
:13	:cp $0728;$06a8
:14	:cp $07a8;$0728
:15	:cp $0450;$07a8
:16	:cp $04d0;$0450
:17	:cp $0550;$04d0
:18	:cp $05d0;$0550
:19	:cp $0650;$05d0
:20	:cp $06d0;$0650
:21	:cp $0750;$06d0
:22	:cp $07d0;$0750
:23	

:done
* now clear DECBM line
*	lda DECBM
*	asl
*	tay
*	ldx text,y

	ldx cursor_base
	lda erase_char
	sta cursor_saved_char
	ldy #19
:loop
	sta >$000000,x
	sta >$010000,x
	inx
	inx
	dey
	bpl :loop

	plp
	rts






* erase 0 - cursor to end of line
* erase 1 - start of line to cursor
* erase 2 - erase line
erase_line_2	ent
	mx %11
	php
	rep #$30
*	lda y
*	asl
*	ldx text,y
	ldx cursor_base
	lda erase_char
	ldy #19
:loop
	sta >$000000,x
	sta >$010000,x
	inx
	inx
	dey
	bpl :loop

	plp
	rts



erase_line_0 ent
*
* erase cursor to end of line.
*
	mx %11

	lda x
	beq erase_line_2

	php
	rep #$30
	lda cursor_base
	clc
	adc cursor_offset
	tax

	sep #$20 ; short m

* odd byte
	ldy cursor_offset
	lda cursor_base+2
	bne :even
	lda erase_char
	sta [cursor_base],y
	inx
	iny
	cpy #40
	beq :exit

:even
	lda erase_char
:loop	sta >$010000,x
	sta >$000000,x
	inx
	iny
	cpy #40
	blt :loop

:exit
	plp
	rts


erase_line_1 ent
* erase start of line to cursor.
	mx %11

	lda x
	cmp #79
	bcs erase_line_2

	php
	rep #$30
	lda cursor_base
	clc
	adc cursor_offset
	tax

	sep #$20 ; short m

	ldy cursor_offset
	lda cursor_base+2
	beq :odd
	lda erase_char
	sta [cursor_base],y
	dex
	dey
	bmi :exit

:odd
	lda erase_char
:loop	sta >$010000,x
	sta >$000000,x
	dex
	dey
	bpl :loop
:exit	plp
	rts

erase_screen_0 ent
* erase cursor to end of screen.
	mx %11
	jsr erase_line_0
	php
	rep #$30

	lda y
	inc
	cmp #24
	bcs :exit
	asl
	tay
	lda erase_char

:loop

	sty r0
	ldx text,y
	ldy #19
:loop0
	sta >$000000,x
	inx
	inx
	dey
	bpl :loop0

	ldy r0
	ldx text,y
	ldy #19
:loop1
	sta >$010000,x
	inx
	inx
	dey
	bpl :loop1

	ldy r0
	iny
	iny
	cpy #24*2
	bcc :loop

:exit
	plp
	rts

erase_screen_1 ent
* erase beginning of screen to cursor.
	mx %11
	jsr erase_line_1

	php
	rep #$30

	lda y
	dec
	bmi :exit
	asl
	tay
	lda erase_char

:loop

	sty r0
	ldx text,y
	ldy #19
:loop0
	sta >$000000,x
	inx
	inx
	dey
	bpl :loop0

	ldy r0
	ldx text,y
	ldy #19
:loop1
	sta >$010000,x
	inx
	inx
	dey
	bpl :loop1

	ldy r0
	dey
	dey
	bpl :loop


:exit
	plp
	rts
	rts

	sav vt100.screen.L
