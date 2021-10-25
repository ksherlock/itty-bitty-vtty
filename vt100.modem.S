
	lst off
	rel
	xc
	xc

	mx %11
	cas se
*	use vt.equ

SCCBREG		equ $c038
SCCAREG		equ $c039
SCCBDATA	equ $c03a
SCCADATA	equ $c03b


SerFlag		equ $e10104 ; 

*
* scc speed:
* 
* time constant = ( clock / (2 * clock mode * baud rate)) - 2
* baud rate = clock / ( 2 * clock mode * (time constant + 2))
*
* clock mode = 1x, 16x, 32x, or 64x (selected via write register 4 bits 6/7)
* clock = 3.6864 MHz crystal (scc runs at 14.31818 / 4 = ~ 3.58 Mhz)
* time constant = write register 12 (low) + 13 (high)
*
*
* see IIgs TN #18 - Do-It-Yourself SCC Access

init_modem ent
*	sep #$30


	stz q_head
	stz q_tail

* reset channel B (modem port)
	ldx #9
	lda #%01_0_1_0_0_0_1
	stx SCCBREG
	sta SCCBREG
	nop
	nop

* x16 clock mode, 1 stop bit, no parity	
	ldx #4
	lda #%01_00_01_0_0
	stx SCCBREG
	sta SCCBREG

* 8 bits/char, rx disabled.
	ldx #3
	lda #%11_0_0_0_0_0_0
	stx SCCBREG
	sta SCCBREG

* 8 data bits, RTS
	ldx #5
	lda #%0_11_0_0_0_1_0
	stx SCCBREG
	sta SCCBREG

* bit 7 = 1 for printer port, 0 for modem port.
* 5/6 = (%10) rcv clock = br output
* 4/3 = (%10) tx clock = br output

	ldx #11
	lda #%0_10_10_0_00
	stx SCCBREG
	sta SCCBREG

* 9600 baud
	ldx #12
	lda #10
	stx SCCBREG
	sta SCCBREG

* 9600 baud
	ldx #13
	lda #0
	stx SCCBREG
	sta SCCBREG


* disable baud rate generator
	ldx #14
	lda #0
	stx SCCBREG
	sta SCCBREG

* enable baud rate generator
	ldx #14
	lda #%000_0_0_0_0_1
	stx SCCBREG
	sta SCCBREG



* 8 bits/char, rx enabled.
	ldx #3
	lda #%11_0_0_0_0_0_1
	stx SCCBREG
	sta SCCBREG


* 8 data bits, tx enabled, RTS
	ldx #5
	lda #%0_11_0_1_0_1_0
	stx SCCBREG
	sta SCCBREG

* disable interrupts
	ldx #15
	lda #0
	stx SCCBREG
	sta SCCBREG

* reset ext/status interrupts
	ldx #0
	lda #%00_010_0_00
	stx SCCBREG
	sta SCCBREG

* enable interrupts
	ldx #1
*	lda #0
	lda #%0_0_0_10_0_0_0 ; inr on rx or special condition.
	stx SCCBREG
	sta SCCBREG

* reset ch b ptr to 0?
	lda SCCBREG


* no vector, master interrupts enabled
	ldx #9
	lda #%00_0_0_1_0_1_0
	stx SCCBREG
	sta SCCBREG
	nop
	nop


* adjust SerFlag so serial IRQs will be handled.
	lda >SerFlag
	ora #%00_000_111 ; channel B interrupts.
	sta >SerFlag

	rts

write_modem ent
	mx %11
* a: byte to send
	tay ; save
*	ldx #0

:mask	= %0010_0100  ; tx buffer empty, clear to send
:wait	stz SCCBREG
	lda SCCBREG
	and #:mask
	cmp #:mask
	bne :wait

	sty SCCBDATA
	rts

read_modem_sync ent
* c set if data read
* v set if overrun
	mx %11
*	ldx #0
	rep #$41 ; clear C + V
	stz SCCBREG
	lda SCCBREG
	and #%0001
	beq :rts

* read reg 1 for overrun 
	lda #1
	sta SCCBREG
	lda SCCBREG
	and #%0010_0000
	beq :ok
* indicate overrun...
	lda #"x"
	sta |$07d0+20
* clear the overrun
	lda #$30 ; reg0, error reset.
	sta SCCBREG
	stz SCCBREG
	sep #$40 ; V
:ok
*	lda #8
*	sta SCCBREG
*	lda SCCBREG
	lda SCCBDATA

* debugging...
	ldx :debug
	sta $1e00,x
	inc :debug

	sec
:rts	rts


:debug	ds 2

buffer equ $1d00

modem_vector	ent
	jml modem_int
modem_int
*
* called in 8-bit native mode, interrupts disabled.
* d = unknown
* a/x/y don't need to be preserved.
* return carry clear if handled, carry set if not.


* check/clear overrun?
	mx %11

	phb
	phk
	plb

	stz SCCBREG
	lda SCCBREG
	and #%0000_0001 ; rx ready.
	beq :nope

:read
	lda SCCBDATA
	ldx q_tail
	sta buffer,x
	inc q_tail

* more?
	stz SCCBREG
	lda SCCBREG
	and #%0000_0001 ; rx ready.
	bne :read
	clc
	bra :finish

:nope

	sec
:finish
* reset errors.
	lda #%00_110_000
	stz SCCBREG
	sta SCCBREG

* reset highest ius
	lda #%00_111_000
	stz SCCBREG
	sta SCCBREG

	plb
	rtl

read_modem ent
read_modem_async ent

	mx %11

	php
	sei
	ldx q_head
	cpx q_tail
	beq :nope

	lda buffer,x
	inc q_head
	plp
	sec
	rts

:nope
	plp
	clc
	rts

q_head	ds 2
q_tail	ds 2
*buffer	ds 256

	sav vt100.modem.L
