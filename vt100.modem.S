
	lst off
	rel
	xc
	xc

	mx %11
	cas se
	use vt.equ
	use debug

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

modem_startup ent
enable_modem ent
*	sep #$30

	php
	sei

	stz read_q_head
	stz read_q_tail
	stz write_q_head
	stz write_q_tail


* zero out the buffer [for CDA debugger]
	ldx #0
]loop	stz read_buffer,x
	inx
	bne ]loop


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


disable_modem ent
* local mode
	mx %11
	php
	sei

	lda SCCBREG ; sync access
	lda #9
	sta SCCBREG
	lda #%01_0_1_0_0_0_1 ; reset channel B.
	sta SCCBREG

	stz read_q_head
	stz read_q_tail
	stz write_q_head
	stz write_q_tail

	plp
	rts


modem_shutdown	ent

	mx %11
	php
	sei

	lda SCCBREG ; sync access
	lda #9
	sta SCCBREG
	lda #%01_0_1_0_0_0_1 ; reset channel B.
	sta SCCBREG


	lda >SerFlag
	and #%11_111_000 ; channel B interrupts.
	sta >SerFlag

	plp
	rts


write_modem_sync ent
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


write_buffer equ $1d00
read_buffer equ $1e00

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

*
* n.b. - vt100 would drop $00 and $7f characters here - I drop them later.
*

	mx %11

	phb
	phk
	plb

	lda SCCBREG ; sync
	stz SCCBREG
	lda SCCBREG
	and #%0000_0001 ; rx ready.
	beq :nope

:read
	lda SCCBDATA
	ldx DPAGE+read_q_head
	sta read_buffer,x
	inc DPAGE+read_q_head

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



modem_io ent
	debug modem_io

	mx %11
	php
	sei
	bit LOCAL
	bmi :local

:write
* send any outbound data...

:mask	= %0010_0100  ; tx buffer empty, clear to send
	ldx write_q_tail
	cpx write_q_head
	beq :read

	lda SCCBREG ; sync
	stz SCCBREG
	lda SCCBREG
	and #:mask
	cmp #:mask
	bne :read

*	ldx write_q_tail
	lda write_buffer,x
	sta SCCBDATA
	inc write_q_tail
:read
	ldx read_q_tail
	cpx read_q_head
	beq :nope
	lda read_buffer,x
	inc read_q_tail

* $00 and $7f dropped here.
	and #$7f
	beq :read 
	cmp #$7f
	beq :read

	plp
	sec
	rts

:nope
	plp
	clc
	rts
	

:local
	ldx write_q_tail
	cpx write_q_head
	beq :nope
	lda write_buffer,x
	inc write_q_tail
	plp
	sec
	rts



write_modem ent
write_modem_async ent

	mx %11
	php
	sei

*	bit LOCAL
*	bmi :local

	ldx write_q_head
	sta write_buffer,x
	inc write_q_head
	plp
	rts
*:local
*	ldx read_q_head
*	sta read_buffer,x
*	inc read_q_head
*	plp
*	rts


write_modem_str ent

; y = address of string (0-terminated)
; inc write_q_head vs inx
; because it wraps at $ff

	mx %10
	php
	sei
*	bit LOCAL
*	bmi :local

:loop	lda |$0000,y
	beq :fini
	ldx write_q_head
	sta write_buffer,x
	inc write_q_head
	iny
	bra :loop

*:local	lda |$0000,y
*	beq :fini
*	ldx read_q_head
*	sta read_buffer,x
*	inc read_q_head
*	iny
*	bra :local


:fini
	plp
	rts




read_modem ent
read_modem_async ent

	mx %11

	php
	sei
	ldx read_q_tail
	cpx read_q_head
	beq :nope

	lda read_buffer,x
	inc read_q_tail
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

	stz read_q_head
	stz read_q_tail
	stz write_q_head
	stz write_q_tail

	plp
	rts

*buffer	ds 256

	sav vt100.modem.L
