
	lst off
	exp off

*
* read modem port
*
*


cmdb	equ $c038
cmda	equ $c039
datab	equ $c03a
dataa	equ $c03b
cout	equ $fded
	

read	mac
	ldx #]1
	if 3=]1
	stx cmda
	lda cmda
	else
	stx cmdb
	lda cmdb
	fin
	sta buffer,x
	<<<

	lst on
	org $0800

	mx %11

	db $01 ; prodos boot id

boot
*	clc
*	xce
*	cli
	sei

	ldx #24
	lda #$80+$0d
:cs	jsr cout
	dex
	bpl :cs	


* just in case.
	lda cmdb
	lda cmdb


init
* reset channel b
	ldx #9
	lda #%01010001
	stx cmdb
	sta cmdb
	nop
	nop

* x16 clock mode, 1 stop bit, no parity	
	ldx #4
	lda #%01000100
	stx cmdb
	sta cmdb

* 8 bits/char, rx disabled.
	ldx #3
	lda #%11000000
	stx cmdb
	sta cmdb

* 8 data bits, RTS
	ldx #5
	lda #%01100010
	stx cmdb
	sta cmdb

	ldx #11
	lda #%01010000
	stx cmdb
	sta cmdb

* 9600 baud
	ldx #12
	lda #10
	stx cmdb
	sta cmdb

* 9600 baud
	ldx #13
	lda #0
	stx cmdb
	sta cmdb


* disable baud rate generator
	ldx #14
	lda #0
	stx cmdb
	sta cmdb

* enable baud rate generator
	ldx #14
	lda #%00000001
	stx cmdb
	sta cmdb



* 8 bits/char, rx enabled.
	ldx #3
	lda #%11000001
	stx cmdb
	sta cmdb


* 8 data bits, tx enabled, RTS
	ldx #5
	lda #%01101010
	stx cmdb
	sta cmdb

* disable interrupts
	ldx #15
	lda #0
	stx cmdb
	sta cmdb

* reset ext/status interrupts
	ldx #0
	lda #%00010000
	stx cmdb
	sta cmdb

* disable interrupts
	ldx #1
	lda #0
	stx cmdb
	sta cmdb

* reset ch b ptr to 0?
	lda cmdb


* status, visible, master interrupts disabled
	ldx #9
	lda #%00010001
	stx cmdb
	sta cmdb
	nop
	nop




* read registers - 0, 1, 2, 3, 8, 10, 12, 13, 15
* 3 is channel A only.
loop


	read 0
	read 1
	read 2
	read 3
	read 8
	read 10
	read 12
	read 13
	read 15

	ldx #15
:cmp	lda buffer,x
	cmp prev,x
	bne :delta
	dex
	bpl :cmp

	bra wailoop	

:delta

	ldx #0

:print
	lda buffer,x
	phx
	pha
	lsr
	lsr
	lsr
	lsr
	tax
	lda hex,x
	jsr cout
	pla
	and #$0f
	tax
	lda hex,x
	jsr cout
	lda #" "
	jsr cout
	plx
	inx
	cpx #16
	bcc :print
	lda #$80+$0d
	jsr cout

* store prev. values.
	ldx #15
:copy	lda buffer,x
	sta prev,x
	dex
	bpl :copy

wailoop
*	wai
	brl loop

	nop
	nop
	stp


hex	asc "0123456789abcdef"
buffer	ds 16
prev	ds 16

	lst off
*	ds \
	ds 1024+$0800-*

	sav modem.bin