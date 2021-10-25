

	lst off
	rel

	xc
	xc
	cas se
	tbx on ; qasm

	use apple2gs.equ
	use vt.equ


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


	dum 0
* cda direct page variables
ptr	ds 2
	dend


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
	jsr content


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
	sta |line_0+38

	lda #" _"
	sta |line_0

	lda #"__"
	ldx #34

]loop	sta |line_0+2,x
	dex
	dex
	bpl ]loop

* bottom line.
* 'L' = $4c = _ but high 
	lda #'L '!$8000 ; keep ' ' high ascii.
	sta |line_23+38

	lda #' L'!$0080 ; keep ' ' high ascii.
	sta |line_23

	lda #'LL'
	ldx #34

]loop	sta |line_23+2,x
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
	sta |line_1+1,x
	dex
	dex
	bpl ]loop

	lda #'LL'
	ldx #36
]loop	sta |line_2+1,x
	dex
	dex
	bpl ]loop

* bottom instructions
	ldx #:instr_len-2
]loop	lda :instr,x
	sta |line_22+1,x
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


* print variables.
content
	php
	sep #$20
	jsr decanm
	jsr dectm
	jsr decbm
	jsr decom
	jsr deckpam
	jsr decckm
	jsr decawm
	jsr decscnm
	jsr lnm
	plp
	rts


decanm
	mx %10
	ldy #line_4+4
	ldx #:str
	jsr print_xy_str
	lda DECANM
	bmi :100
	ldx #:vt52
	jmp print_xy_str

:100	ldx #:vt100
	jmp print_xy_str

:str	asc "DECANM: ",00
:vt100	asc "vt100",00
:vt52	asc "vt52",00


dectm
	mx %10
	ldy #line_5+4
	ldx #:str
	jsr print_xy_str
	lda DPAGE+DECTM
	inc
	jmp print_number

:str	asc "DECTM: ",00

decbm
	mx %10
	ldy #line_6+4
	ldx #:str
	jsr print_xy_str
	lda DPAGE+DECBM
	inc
	jmp print_number

:str	asc "DECBM: ",00


decom
	mx %10
	ldy #line_7+4
	ldx #:str
	jsr print_xy_str
	lda DPAGE+DECOM
	inc
	jmp print_number

:str	asc "DECOM: ",00

deckpam
	mx %10
	ldy #line_8+4
	ldx #:str
	jsr print_xy_str
	lda DPAGE+DECKPAM
	jmp print_check

:str	asc "DECKPAM: ",00

decckm
	mx %10
	ldy #line_9+4
	ldx #:str
	jsr print_xy_str
	lda DPAGE+DECCKM
	jmp print_check

:str	asc "DECCKM: ",00


decawm
	mx %10
	ldy #line_10+4
	ldx #:str
	jsr print_xy_str
	lda DPAGE+DECAWM
	jmp print_check

:str	asc "DECAWM: ",00


decscnm
	mx %10
	ldy #line_10+4
	ldx #:str
	jsr print_xy_str
	lda DPAGE+DECSCNM
	jmp print_check

:str	asc "DECSCNM: ",00


lnm
	mx %10
	ldy #line_12+4
	ldx #:str
	jsr print_xy_str
	lda DPAGE+LNM
	jmp print_check

:str	asc "LNM: ",00


print_xy_str
	mx %10
:loop	lda |$0,x
	beq :end
	sta |$0,y
	inx
	iny
	bra :loop
:end	
	rts

print_check
	mx %10
	bmi :set
	ldx #:off
	jmp print_xy_str
:set	ldx #:on
	jmp print_xy_str

:on	asc "on",00
:off	asc "off",00

print_number
	mx %10
	cmp #20
	bcs :2
	cmp #10
	bcs :1
:0	ora #"0"
	sta |$0,y
	iny
	rts

:2	pha
	lda #"2"
	sta |$0,y
	iny
	pla
	sec
	sbc #20
	bra :0
:1	pha
	lda #"1"
	sta |$0,y
	iny
	pla
	sec
	sbc #10
	bra :0



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



line_0	equ $0400
line_1	equ $0480
line_2	equ $0500
line_3	equ $0580
line_4	equ $0600
line_5	equ $0680
line_6	equ $0700
line_7	equ $0780
line_8	equ $0428
line_9	equ $04a8
line_10	equ $0528
line_11	equ $05a8
line_12	equ $0628
line_13	equ $06a8
line_14	equ $0728
line_15	equ $07a8
line_16	equ $0450
line_17	equ $04d0
line_18	equ $0550
line_19	equ $05d0
line_20	equ $0650
line_21	equ $06d0
line_22	equ $0750
line_23	equ $07d0


	sav vt100.cda.L
