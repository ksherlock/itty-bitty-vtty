
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



init_modem ent
*	sep #$30
* reset channel B (modem port)
	ldx #9
	lda #%01010001
	stx SCCBREG
	sta SCCBREG
	nop
	nop

* x16 clock mode, 1 stop bit, no parity	
	ldx #4
	lda #%01000100
	stx SCCBREG
	sta SCCBREG

* 8 bits/char, rx disabled.
	ldx #3
	lda #%11000000
	stx SCCBREG
	sta SCCBREG

* 8 data bits, RTS
	ldx #5
	lda #%01100010
	stx SCCBREG
	sta SCCBREG

	ldx #11
	lda #%01010000
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
	lda #%00000001
	stx SCCBREG
	sta SCCBREG



* 8 bits/char, rx enabled.
	ldx #3
	lda #%11000001
	stx SCCBREG
	sta SCCBREG


* 8 data bits, tx enabled, RTS
	ldx #5
	lda #%01101010
	stx SCCBREG
	sta SCCBREG

* disable interrupts
	ldx #15
	lda #0
	stx SCCBREG
	sta SCCBREG

* reset ext/status interrupts
	ldx #0
	lda #%00010000
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
	lda #%00010001
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
