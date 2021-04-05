
	lst off
	exp off

*
* read slot 7 ssc card.
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



SSC	equ $c088+$70

init
* command register - DTR+, IRQ-, TX IRQ-, ECHO-, PARITY-
	lda #%0000_1011
	sta SSC+2
*control - 9600, BRG, /1
	lda #%0_00_1_1110
	sta SSC+3



* read 4 registers
loop

	; status first
	lda SSC+1
	sta buffer+1

	lda SSC+0
	sta buffer+0

	lda SSC+2
	sta buffer+2

	lda SSC+3
	sta buffer+3


	ldx #3
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
	cpx #4
	bcc :print
	lda #$80+$0d
	jsr cout

* store prev. values.
	ldx #3
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

	sav scc.bin