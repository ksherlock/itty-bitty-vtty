
	lst off
	cas se

	rel
	xc
	xc

	use apple2gs.equ


	mx %11



*
*
* keypress @ 44.1 - 28 samples of $40, 29 samples of $b0
*
* beep - repeat keypress 53 times
*
* by adjusting rate, only need 1 sample each.
*
* w/ 2 oscillators, scan rate = 223.7 kHz ~5x 44.1 
* 28 samples * 5 = 142
* res = 7.  (1 << 16) / 142 = ~ 461  
* freq = 461, res = 7, wave size = 256 --> n * 461 >> 16
* 
*


*
* vt52
* keypress - ~730 samples, $40, curve to 0 or $b0, curve to 0
* beep 14 keypresses
* 
*


bic	mac
	if #=]1
	and ]1!$ffff
	else
	err 1 ; immediate only.
	fin
	<<<

docwait	mac
	if MX<2
	err 1 ; 8-bit m only
	fin
wait	lda SGCONTROL
	bmi wait
	<<<

docmode mac
	docwait
	bic #%01000000 ; DOC mode
	ora #%00100000 ; auto-incr
	ora #%0000_1111 ; max volume.
	sta SGCONTROL
	<<<

rammode	mac
	docwait
	ora #%01100000 ; RAM mode, auto-incr
	sta SGCONTROL
	<<<


init_audio ent

	docmode

* 4 oscillators. -- (2 for key, 2 for beep -- stereo!)
	lda #$e1
	sta SGADDRL

	lda #4*2
	sta SGDATA

* control registers
* just set them off.  channels will be set when they fire.

	lda #$a0
	sta SGADDRL
	lda #%0000_0_01_1 ; ch 0, interrupts off, 1-shot, halted.
	sta SGDATA
	sta SGDATA
	sta SGDATA
	sta SGDATA



* freq low
	lda #$00
	sta SGADDRL
	lda #<650
	sta SGDATA
	sta SGDATA
	sta SGDATA
	sta SGDATA

* freq high
	lda #$20
	sta SGADDRL
	lda #>650
	sta SGDATA
	sta SGDATA
	sta SGDATA
	sta SGDATA

* volume
	lda #$40
	sta SGADDRL
	lda #$ff
	sta SGDATA
	sta SGDATA
	sta SGDATA
	sta SGDATA

* wave table
	lda #$80
	sta SGADDRL
	lda #0 ; page 0
	sta SGDATA
	sta SGDATA
	inc ; page 1
	sta SGDATA
	sta SGDATA



* wave table size
	lda #$c0
	sta SGADDRL
	lda #%00_000_111 ; 256 bytes, 16-bit shift
	sta SGDATA
	sta SGDATA
	sta SGDATA
	sta SGDATA


; now copy the data....
	rammode
	stz SGADDRL
	stz SGADDRH

	ldy #key_size
	ldx #0
]loop	lda key_data,x
	sta SGDATA
	inx
	dey
	bpl ]loop

	stz SGADDRL
	lda #1
	sta SGADDRH
	ldy #beep_size
	ldx #0
]loop	lda beep_data,x
	sta SGDATA
	inx
	dey
	bpl ]loop

	rts


beep	ent
	; fire osc 2 + 3
	docmode

	lda #$a0+2
	sta SGADDRL
	lda #%0000_0_01_0 ; ch 0, interrupts off, 1-shot, running.
	ldx #%0001_0_01_0 ; ch 1, interrupts off, 1-shot, running.
	sta SGDATA
	stx SGDATA

	rts


key_data
	db $01
	db $ff
	db $00
key_size equ *-key_data

beep_data
	lup 53
	db $01
	db $ff
	--^
	db $0
beep_size equ *-beep_data

	sav vt100.beep.L
