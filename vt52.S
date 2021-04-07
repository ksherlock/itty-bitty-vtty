	lst off
	exp off
	xc
	xc
	rel

* vt52 emulator.
* not supported - graphics, screen hold.
*
*
*
* todo -- beep -- use ensoniq?
* todo -- vgc int for cursor blink
*
*
* in general, 8-bit m/x.
*
*
*



SET80VID	equ $c00d
SETALTCHAR	equ $c00f
TXTSET		equ $c051
KEYMOD		equ $c025
KEYSTROBE	equ $c010
KBD		equ $c000
VGCINT		equ $c023


kmShift		equ %0000_0001
kmControl	equ %0000_0010
kmCapsLock	equ %0000_0100
kmRepeat	equ %0000_1000
kmKeypad	equ %0001_0000
kmUpdateMod	equ %0010_0000
kmOption	equ %0100_0000
kmCommand	equ %1000_0000


* interrupt vectors.  JMP ABSLONG.
IRQ1SEC		equ $e10054
IRQQTR		equ $e10038
IRQVBL		equ $e10030
IRQSND		equ $e1002c

	ent init,main,vt52


	dum 0
text00	adrl 0
text01	adrl 0
state	dw 0
mode	dw 0
x	dw 0
y	dw 0
key	dw 0
mod	dw 0


* cursor 

cursor_ptr adrl 0
cursor_saved_char dw 0
cursor_state dw 0


	dend

	mx %11
main
	clc
	xce
	cli

	jsr init
	mx %00
	lda #0
loop
	sep #$30
:again	lda $c000
	bmi keypress
	bra :again

keypress
	and #$7f
	sta key
	sta KEYSTROBE
	lda KEYMOD  ; %1000_0000
	sta mod
	bit #kmOption!kmCommand
	bne :command

	bit #kmKeypad
	bne :keypad
	bit #kmControl
	bne :ctrl


	lda key
	cmp #' '
	bcs :notctrl


* control char but control not set.
* need to differentiate arrow keys vs control keys
*
* arrow keys depend on mode....
	ldx #:atsize-2
]loop	cmp :arrowtable,x
	beq :remap
	dex
	dex
	bmi :send
	bra ]loop
:remap
	lda :arrowtable+1,x
	sta key
	lda #$1b
	jsr vt52
	bra :ctrl

:arrowtable
	db $08,'D' ; left arrow
	db $0a,'B' ; down arrow
	db $0b,'A' ; up arrow
	db $15,'C' ; right arrow
:atsize equ *-:arrowtable

:ctrl	lda key
	bra :send

:notctrl
	cmp #$7f ; delete is a special case.
	bne :send
	lda #$08
:send	jsr vt52
	bra loop


:command
* or option
	bra loop

:keypad
*
	bra loop




init
	sep #$30
	sta TXTSET
	sta SET80VID
	sta SETALTCHAR
	rep #$30

	stz x
	stz y
	stz mode
	stz state

	lda #$0400
	sta text00
	stz text00+2

	sta text01
	sta cursor_ptr

	lda #$0001
	sta text01+2
	sta cursor_ptr+2

	jmp clear_all


cc	mac
	ldx #38
]loop	sta ]1,x
	stal $010000+]1,x
	dex
	dex
	bpl ]loop
	<<<

cp	mac
	ldx #38
]loop	lda ]1,x
	sta ]2,x
	ldal $010000+]1,x
	stal $010000+]2,x
	dex
	dex
	bpl ]loop
	<<<


* needs to restore mx
clear_eol
	mx %11
	php
	sep #$30
	lda x
	lsr
	tay
	lda #" "
	bcc :even

	sta (text00),y
	iny
:even
	cpy #80/2
	bcs :rts
	sta [text01],y
	sta (text00),y
	iny
	cpy #40
	bra :even
:rts	plp
	rts

* needs to restore mx
clear_eos
	mx %11
	ldx #0 ; for jmp (,x)
	lda x
	ora y
	beq :all

	lda x
	beq :x0
	jsr clear_eol
	lda y
	inc
	bra :x1
:x0
	lda y
:x1	cmp #23
	bcs :rts
	asl
	tax
:all	php ; clear_table will plp.
	rep #$30
	lda #"  "
	jmp (clear_table,x)

:rts	rts

clear_all
	mx %00
	php
	rep #$30
	lda #"  " ; high bit
c00	cc $0400
c01	cc $0480
c02	cc $0500
c03	cc $0580
c04	cc $0600
c05	cc $0680
c06	cc $0700
c07	cc $0780
c08	cc $0428
c09	cc $04a8
c10	cc $0528
c11	cc $05a8
c12	cc $0628
c13	cc $06a8
c14	cc $0728
c15	cc $07a8
c16	cc $0450
c17	cc $04d0
c18	cc $0550
c19	cc $05d0
c20	cc $0650
c21	cc $06d0
c22	cc $0750
c23	cc $07d0
	plp
	rts

clear_table
	dw c00,c01,c02,c03,c04,c05,c06,c07,c08,c09
	dw c10,c11,c12,c13,c14,c15,c16,c17,c18,c19
	dw c20,c21,c22,c23


scroll_down
	mx %11

	php
	rep #$30
	cp $0480;$0400
	cp $0500;$0480
	cp $0580;$0500
	cp $0600;$0580
	cp $0680;$0600
	cp $0700;$0680
	cp $0780;$0700
	cp $0428;$0780
	cp $04a8;$0428
	cp $0528;$04a8
	cp $05a8;$0528
	cp $0628;$05a8
	cp $06a8;$0628
	cp $0728;$06a8
	cp $07a8;$0728
	cp $0450;$07a8
	cp $04d0;$0450
	cp $0550;$04d0
	cp $05d0;$0550
	cp $0650;$05d0
	cp $06d0;$0650
	cp $0750;$06d0
	cp $07d0;$0750

	lda #"  "
	cc $07d0
	plp
	rts

scroll_up
	php
	rep #$30
	cp $0750;$07d0
	cp $06d0;$0750
	cp $0650;$06d0
	cp $05d0;$0650
	cp $0550;$05d0
	cp $04d0;$0550
	cp $0450;$04d0
	cp $07a8;$0450
	cp $0728;$07a8
	cp $06a8;$0728
	cp $0628;$06a8
	cp $05a8;$0628
	cp $0528;$05a8
	cp $04a8;$0528
	cp $0428;$04a8
	cp $0780;$0428
	cp $0700;$0780
	cp $0680;$0700
	cp $0600;$0680
	cp $0580;$0600
	cp $0500;$0580
	cp $0480;$0500
	cp $0400;$0480

	lda #"  "
	cc $0400
	plp
	rts

draw_char
	mx %11
	; a = char to draw
	ora #$80
	tax
	lda x
	lsr
	tay
	txa
	bcs :odd

	sta [text01],y
	inc x
	jmp update_cursor

:odd
	sta (text00),y
	lda x
	cmp #79
	bcs :rts
	inc x
:rts	jmp update_cursor




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




* based on testing, control handling happens first. ESC within an ESC Y sequence resets to ESC state.


vt52
	mx %11

	and #$7f
	cmp #' '
	bcs :normal
	asl
	tax
	jmp (ctrl_table,x)
:normal
	ldx state
	jmp (st_table,x)

st_table
	dw state_0,state_1,state_2,state_3


state_0
	and #$7f
	cmp #$7f
	beq :rts
	jsr draw_char
:rts
	rts

state_1 ; ESC encountered

:MIN	equ '<'
:MAX	equ '\'

	stz state
	and #$7f
	cmp #:MIN
	bcc :rts

	cmp #:MAX+1
	bcs :rts
	sec
	sbc #:MIN
	asl
	tax
	jmp (:table,x)
:rts
	rts

:table
	dw esc_lt ; <
	dw esc_eq ; =
	dw esc_gt ; >
	dw :rts ; ?
	dw :rts ; @
	dw esc_A ; A
	dw esc_B ; B
	dw esc_C ; C
	dw esc_D ; D
	dw :rts ; E
	dw esc_F ; F
	dw esc_G ; G
	dw esc_H ; H
	dw esc_I ; I
	dw esc_J ; J
	dw esc_K ; K
	dw :rts ; L
	dw :rts ; M
	dw :rts ; N
	dw :rts ; O
	dw :rts ; P
	dw :rts ; Q
	dw :rts ; R
	dw :rts ; S
	dw :rts ; T
	dw :rts ; U
	dw :rts ; V
	dw :rts ; W
	dw :rts ; X
	dw esc_Y ; Y
	dw esc_Z ; Z
	dw esc_[ ; [
	dw esc_\ ; \



state_2 ; ESC Y encountered, part 1
* out of bounds line is ignored.
	inc state
	inc state

	and #$7f
	sec
	sbc #' '
	cmp #24
	bcs :rts
	sta y
	jmp update_cursor
:rts	rts

state_3 ; ESC Y encountered, part 2
* out of bounds column is ignored.
* vt52 doc claims it moves to the rightmost column but this
* doesn't reflect actual behavior.

	stz state

	and #$7f
	sec
	sbc #' '
	cmp #80
	bcs :rts
	sta x
	jmp update_cursor
:rts	rts



ctrl_table
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
ctrl_05
ctrl_06
ctrl_0b
ctrl_0c
ctrl_0e
ctrl_0f
ctrl_10
ctrl_11
ctrl_12
ctrl_13
ctrl_14
ctrl_15
ctrl_16
ctrl_17
ctrl_18
ctrl_19
ctrl_1a
ctrl_1c
ctrl_1d
ctrl_1e
ctrl_1f
	rts

ctrl_07 ; ring the bell.
	rts

ctrl_1b ; escape -
	lda #2
	sta state
	rts

ctrl_09 ; tab

	lda x
	cmp #73
	bcs :one

	clc
	adc #8
	and #$07!$ff
	sta x
	bra :update
:one
	cmp #79
	bcs :rts
	inc x

:update
	jmp update_cursor
:rts	rts

ctrl_0a ; line feed - cursor down w/ scroll

	lda y
	cmp #23
	blt :simple
	jmp scroll_down

:simple
	inc y
	jmp update_cursor

ctrl_0d ; carriage return - cursor to column 0.
	stz x
	jmp update_cursor

esc_A ; cursor up w/o scroll

	lda y
	beq :rts
	dec y
	jmp update_cursor
:rts	rts

esc_B ; cursor down w/o scroll

	lda y
	inc
	cmp #24
	bcs :rts
	inc y
	jmp update_cursor
:rts	rts

esc_C ; cursor right w/o wrap

	lda x
	inc
	cmp #79
	bcs :rts
	inc x
	jmp update_cursor
:rts	rts


esc_D ; cursor left w/o wrap
ctrl_08 ; back space - cursor left w/o wrap

	lda x
	beq :rts
	dec x
	jmp update_cursor
:rts	rts


esc_F ; enter graphics mode
	lda #%0010
	tsb mode
	rts
esc_G ; exit graphics mode
	lda #%0010
	trb mode
	rts

esc_H ; cursor home
	stz x
	stz y
	jmp update_cursor

esc_I ; reverse line feed - cursor up w/ scroll

	lda y
	bne :simple
	jmp scroll_up
:simple
	dec y
	jmp update_cursor



esc_J ; erase to end of screen
	jmp clear_eos

esc_K ; erase to end-of-line
	jmp clear_eol

esc_Y ; direct cursor addressing
	lda #4
	sta state
	rts

esc_Z ; identify terminal.
	; return ESC / K
	rts

esc_[ ; enter hold screen mode
	lda #%0100
	tsb mode
	rts

esc_\ ; exit hold screen mode
	lda #%0100
	trb mode
	rts

esc_eq ; enter alternate keypad mode
	lda #%0001
	tsb mode
	rts
esc_gt ; exit alternate keypad mode
	lda #%0001
	trb mode
	rts


esc_lt ; vt100 - enter ANSI mode (exit vt52 mode).
	rts



update_cursor
* todo - cursor stuff.
	mx %11
	php
	rep #$30

	lda y
	asl
	tay
	lda text,y
	sta text00
	sta text01
	sta cursor_ptr
	lda x
	lsr
	clc
	adc cursor_ptr
	sta cursor_ptr

	plp
	rts

cursor_off
	mx %11
	php
	sei
*	sep #$20+4
	lda cursor_state
	bmi :rts

	lsr
	bcc :simple

	lda x
	lsr
	lda cursor_saved_char

	bcc :even
	sta (cursor_ptr)
	bra :simple

:even
	sta [cursor_ptr]

:simple
	lda #$80
	sta cursor_state

:rts	plp
	rts


cursor_on
	mx %11
	php
	sei
*	sep #$20+4
	lda cursor_state
	bpl :rts

	stz cursor_state
:rts	plp
	rts

cursor_int
* cursor interrupt - swap the char w/
	mx %11
	php

	lda cursor_state
	bmi :rts
	eor #1
	sta cursor_state
	lsr
	bcc :off
:on
	lda x
	lsr
	bcc :even_on
	lda (cursor_ptr)
	sta cursor_saved_char
	lda #'_'
	sta (cursor_ptr)
	bra :rts
:even_on
	lda [cursor_ptr]
	sta cursor_saved_char
	lda #'_'
	sta [cursor_ptr]
	bra :rts

:off
	lda x
	lsr
	lda cursor_saved_char
	bcc :even_off
	sta (cursor_ptr)
	bra :rts
:even_off
	sta [cursor_ptr]

:rts	plp
	clc
	rtl


*	lst on
*	sym on
	sav vt52.L

