
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

	php
	sei

	stz q_head
	stz q_tail

	lda SCCBREG ; sync access
	ldx #0

]loop
	lda :table,x
	bmi :done
	sta SCCBREG
	inx
	lda :table,x
	sta SCCBREG
	inx
	bra ]loop
:done

* adjust SerFlag so serial IRQs will be handled.
	lda >SerFlag
	ora #%00_000_111 ; channel B interrupts.
	sta >SerFlag

	plp
	rts

:table  ; register, value
*	db 9,%01_0_1_0_0_0_1 ; reset channel B (modem port) - handled @ startup.
	db 4,%01_00_01_0_0 ; x16 clock, 1 stop bit, no parity
	db 3,%11_0_0_0_0_0_0 ; 8 bits, rx disabled
	db 5,%0_11_0_0_0_1_0 ; 8 bits, RTS
	db 11,%0_10_10_0_00 ; modem port, rcv/tx clock = br
	db 12,10 ; 9600 baud (low)
	db 13,0 ; 9600 baud (high)
	db 14,0 ; disable baud rate generator
	db 14,%000_0_0_0_0_1 ; enable baud rate generator
	db 3,%11_0_0_0_0_0_1 ; 8 bits, rx enabled
	db 5,%0_11_0_1_0_1_0 ; 8 bits, tx enabled, RTS
	db 15,0 ; disable external interrupts
	db 0,%00_010_0_00 ; reset ext/status interrupts
	db 1,%0_0_0_10_0_0_0 ; interrupts on rx or special condition
	db 9,%00_0_0_1_0_1_0 ; master interrupts enabled.
	db -1,-1

write_modem ent
	mx %11
* a: byte to send
	tay ; save
*	ldx #0
	php


:mask	= %0010_0100  ; tx buffer empty, clear to send
:wait	
	cli ; guard scc register access.
	sei
	stz SCCBREG
	lda SCCBREG
	and #:mask
	cmp #:mask
	bne :wait

	sty SCCBDATA
	plp
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


	sec
:rts	rts


buffer equ $1e00

modem_vector	ent
	jml modem_int
modem_int
*
* called in 8-bit native mode, interrupts disabled.
* d = unknown
* a/x/y don't need to be preserved.
* return carry clear if handled, carry set if not.

* doesn't access direct page.

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

reset_modem_buffer ent
	mx %11
	php
	sei
	stz q_head
	stz q_tail
	plp
	rts

q_head	ds 2
q_tail	ds 2
*buffer	ds 256

	sav vt100.modem.L
