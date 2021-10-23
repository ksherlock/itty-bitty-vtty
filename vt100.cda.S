

	lst off
	rel

	xc
	xc
	cas se
	tbx on ; qasm

	use apple2gs.equ


* alternate character set
* $00-$1f = upper inverse ( asci value - $40)
* $20-$3f = special inverse (ascii value)
* $40-$4f = mouse text 
* $60-$7f = lower inverse (= ascii value)
* $80-$9f = upper [redundant]
* $a0-$bf = special (high ascii)
* $c0-$df = upper (high ascii)
* $e0-$ff = lower (high ascii)


* 40-column control panel
* TODO - if 80 column set in preferences, draw centered in 80-column mode

init_cda ent
	php
	rep #$30
	psl #handle
	_InstallCDA
	plp
	rts

handle	adrl Header ; can use a fake handle for now, until we need to _RemoveCDA
Header
	str 'Virtual Terminal'
	adrl start
	adrl shutdown

shutdown
	mx %00
	rtl

start
	mx %00

	phb
	phd

	phk
	plb

	sep #$30
	sta TXTSET
	sta CLR80VID
	sta SETALTCHAR
	rep #$30

	jsr clear
	jsr box


:keyloop
	lda KBD
	bpl :keyloop
	sta KEYSTROBE

	pld
	plb
	rtl


clear
	ldx #23*2
	lda #"  "
:loop
	ldy text,x

]offset	equ 0
	lup 20
	sta |0+]offset,y
]offset	equ ]offset+2
	--^

	dex
	dex
	bpl :loop
	rts


box
	php

* top line
	lda #"_ "
	sta $0400+38

	lda #" _"
	sta $0400

	lda #"__"
	ldx #34

]loop	sta $0400+2,x
	dex
	dex
	bpl ]loop

* bottom line.
* 'L' = $4c = _ but high 
	lda #'L '!$8000 ; keep ' ' high ascii.
	sta $07d0+38

	lda #' L'!$0080 ; keep ' ' high ascii.
	sta $07d0

	lda #'LL'
	ldx #34

]loop	sta $07d0+2,x
	dex
	dex
	bpl ]loop


* sides
	sep #$20
	lda #'Z'
	ldx #21*2 ; skip top/bottom lines.
]loop	ldy text+2,x
	sta |$0,y
	dex
	dex
	bpl ]loop

	sep #$20
	lda #'_'
	ldx #21*2 ; skip top/bottom lines.
]loop	ldy text+2,x
	sta |$0+39,y
	dex
	dex
	bpl ]loop


	rep #$20

* title
	ldx #36
]loop	lda :title,x
	sta |$0480+1,x
	dex
	dex
	bpl ]loop

	lda #'LL'
	ldx #36
]loop	sta |$0500+1,x
	dex
	dex
	bpl ]loop

* bottom instructions
	ldx #:instr_len-2
]loop	lda :instr,x
	sta |$0750+1,x
	dex
	dex
	bpl ]loop



	plp
	rts

:instr
	asc " Select: ",'H'," ",'U'," ",'J'," ",'K'
	asc "  Cancel:Esc  Save: ",'M'," "
:instr_len equ *-:instr
	err :instr_len&1


:title
	asc " Virtual Terminal "
	ds 38-18,' ' 


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



	sav vt100.cda.L
