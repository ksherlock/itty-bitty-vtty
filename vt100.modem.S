
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


*
* scc speed:
* 
* time constant = ( clock / (2 * clock mode * baud rate)) - 2
* baud rate = clock / ( 2 * clock mode * (time constant + 2))
*
* clock mode = 1x, 16x, 32x, or 64x (selected via write register 4 bits 6/7)
* clock = 3.6864 MHz crystal (scc runs at 14.31818 / 4 = ~ 3.58 Mhz)
* time constant = write register 12 (low) + 13 (high)


init_modem ent
*	sep #$30
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

* disable interrupts
	ldx #1
	lda #0
	stx SCCBREG
	sta SCCBREG

* reset ch b ptr to 0?
	lda SCCBREG


* status, visible, master interrupts disabled
	ldx #9
	lda #%00_0_1_0_0_0_1
	stx SCCBREG
	sta SCCBREG
	nop
	nop


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

read_modem ent
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
	sec
:rts	rts


	sav vt100.modem.L
