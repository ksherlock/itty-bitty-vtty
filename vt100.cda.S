

	lst off
	rel

	xc
	xc
	cas se
	tbx on ; qasm

	use apple2gs.equ
	use vt.equ
	use debug


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


*
* rom 0/1 doesn't include _RemoveCDA in ROM so it can't be removed.
* additionally, _InstallCDA has bugs.
* so, for now, disable on ROM 1.

cda_startup ent
	php
	rep #$30

	jsr $fe1f ; idroutine.  y = rom
	cpy #3
	bcc :nope

*
* rom 1 IIgs InstallCDA clobbers $3c-$43 on the direct page
*

	phd
	pea #0
	pld

	psl #handle
	_InstallCDA

	pld

:nope
	plp
	rts

cda_shutdown ent
	mx %00

	jsr $fe1f ; idroutine.  y = rom
	cpy #3
	bcc :nope

	phd
	pea #0
	pld


	psl #handle
	_RemoveCDA

	pld

:nope
	rts


handle	adrl Header ; can use a fake handle for now, until we need to _RemoveCDA
Header
	str 'Virtual Terminal'
	adrl start
	adrl shutdown
* variables.
page	ds 2


MAX_PAGE	equ 8
pages	dw variables
	dw hexdump_r
	dw hexdump_w
	dw ssc_registers

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

	stz page
	jsr clear
	jsr box

main

	jsr clear_inner
	ldx page
	jsr (pages,x)



:keyloop
	sep #$30
	lda KBD
	bpl :keyloop
	sta KEYSTROBE
	rep #$30

	and #$7f

	cmp #$1b
	beq :exit

	cmp #$08 ; left
	beq :left
	cmp #$15
	beq :right
	bra :keyloop

:exit
	pld
	plb
	rtl

:left	lda page
	dec
	dec
	bpl :lok
	lda #MAX_PAGE-2
:lok	sta page
	bra main

:right	lda page
	inc
	inc
	cmp #MAX_PAGE
	bcc :rok
	lda #0
:rok	sta page
	bra main



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

clear_inner
* clear the inner contents.
	ldx #16*2
	lda #"  "
:loop	ldy text+8,x

]offset	equ 4
	lup 16
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
variables
	php
	sep #$20
	jsr local
	jsr decanm
	jsr decom
	jsr deckpam
	jsr decckm
	jsr decawm
	jsr decarm
	jsr decscnm
	jsr deccolm
	jsr lnm
	jsr sgr
	jsr dectm
	jsr decbm
	jsr decx
	jsr decy
	plp
	rts

local
	mx %10
	ldy #line_4+4
	ldx #:str
	jsr print_xy_str
	lda DPAGE+LOCAL
	jmp print_on_off

:str	asc "LOCAL:   ",00

decanm
	mx %10
	ldy #line_5+4
	ldx #:str
	jsr print_xy_str
	lda DPAGE+DECANM
	bmi :100
	ldx #:vt52
	jmp print_xy_str

:100	ldx #:vt100
	jmp print_xy_str

:str	asc "DECANM:  ",00
:vt100	asc "vt100",00
:vt52	asc "vt52",00



decom
	mx %10
	ldy #line_6+4
	ldx #:str
	jsr print_xy_str
	lda DPAGE+DECOM
	jmp print_on_off

:str	asc "DECOM:   ",00

deckpam
	mx %10
	ldy #line_7+4
	ldx #:str
	jsr print_xy_str
	lda DPAGE+DECKPAM
	jmp print_on_off

:str	asc "DECKPAM: ",00

decckm
	mx %10
	ldy #line_8+4
	ldx #:str
	jsr print_xy_str
	lda DPAGE+DECCKM
	jmp print_on_off

:str	asc "DECCKM:  ",00


decawm
	mx %10
	ldy #line_9+4
	ldx #:str
	jsr print_xy_str
	lda DPAGE+DECAWM
	jmp print_on_off

:str	asc "DECAWM:  ",00

decarm
	mx %10
	ldy #line_10+4
	ldx #:str
	jsr print_xy_str
	lda DPAGE+DECARM
	jmp print_on_off

:str	asc "DECARM:  ",00

decscnm
	mx %10
	ldy #line_11+4
	ldx #:str
	jsr print_xy_str
	lda DPAGE+DECSCNM
	jmp print_on_off

:str	asc "DECSCNM: ",00


deccolm
	mx %10
	ldy #line_12+4
	ldx #:str
	jsr print_xy_str
	lda DPAGE+DECCOLM
	jmp print_on_off

:str	asc "DECCOLM: ",00


lnm
	mx %10
	ldy #line_13+4
	ldx #:str
	jsr print_xy_str
	lda DPAGE+LNM
	jmp print_on_off

:str	asc "LNM:     ",00


sgr
	mx %10
	ldy #line_14+4
	ldx #:str
	jsr print_xy_str
	lda DPAGE+SGR
	jmp print_binary

:str	asc "SGR:     ",00


dectm
	mx %10
	ldy #line_15+4
	ldx #:str
	jsr print_xy_str
	lda DPAGE+DECTM
	inc
	jmp print_number

:str	asc "DECTM:   ",00

decbm
	mx %10
	ldy #line_16+4
	ldx #:str
	jsr print_xy_str
	lda DPAGE+DECBM
	inc
	jmp print_number

:str	asc "DECBM:   ",00


decx
	mx %10
	ldy #line_17+4
	ldx #:str
	jsr print_xy_str
	lda DPAGE+x
	and #$7f
	inc
	jmp print_number

:str	asc "X:       ",00

decy
	mx %10
	ldy #line_18+4
	ldx #:str
	jsr print_xy_str
	lda DPAGE+y
	inc
	jmp print_number

:str	asc "Y:       ",00


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

print_on_off
	mx %10
	bmi :set
	ldx #:off
	jmp print_xy_str
:set	ldx #:on
	jmp print_xy_str

:on	asc "on",00
:off	asc "off",00

print_number
	debug print_number
*
* print a base-10 number, 0-255
* a = #
	mx %10


	ldx #0

:100
	cmp #100
	bcc :10x
	inx
*	sec
	sbc #100
	bra :100

:10x
	cpx #0
	beq :10

	pha
	txa
*	clc
*	adc #"0"
	ora #"0"
	sta |$0,y
	iny
	pla
	ldx #0

:10
	cmp #10
	bcc :1x
	inx
	sbc #10
	bra :10

:1x
	cpx #0
	beq :1
	pha
	txa
*	clc
*	adc #"0"
	ora #"0"
	sta |$0,y
	iny
	pla

:1
*	clc
*	adc #"0"
	ora #"0"
	sta |$0,y
	iny
	rts

print_binary
	mx %10
*	pha
*	lda #"%"
*	sta |$0,y
*	iny
*	pla
	lup 8
	asl
	pha
	lda #0
	adc #"0"
	sta |$0,y
	iny
	pla
	--^
	rts

print_hex
	mx %10

	xba
	lda #0
	xba
	pha
	lsr
	lsr
	lsr
	lsr
	tax
	lda hex,x
	sta |$0,y
	iny
	pla
	and #$0f
	tax
	lda hex,x
	sta |$0,y
	iny
	rts


hexdump_r
*
* $1e00 buffer
*

	mx %00

	lda DPAGE+read_q_tail
	sec
	sbc #8*16
	and #$00ff
	ora #$1e00
	jmp hexdump_common


hexdump_w
*
* $1d00 buffer
*
	mx %00


	lda DPAGE+write_q_tail
	sec
	sbc #8*16
	and #$00ff
	ora #$1d00
	jmp hexdump_common


hexdump_common
*
* a = address to start.



:screen	equ 0
:screen2	equ 2
*:offset	equ 4
:ptr	equ 6
:count	equ 8
:row	equ 10
:c	equ 12

	mx %00
	debug hexdump


	php
	sta :ptr
	lda #0

*	stz :offset

	sep #$20

	ldx #4*2
	stx :row


:one_row

	ldx :row
	ldy text,x
	sty :screen
	sty :screen2



	lda #8
	sta :count

:one_byte

	lda (:ptr)
	inc :ptr

	sta :c
	lsr
	lsr
	lsr
	lsr
	tax
	lda hex,x
	ldy :screen
	sta |$04,y
	iny
	lda :c
	and #$0f
	tax
	lda hex,x
	sta |$04,y
	iny
	lda #" "
	sta |$04,y
	iny
	sty :screen


* ascii
	ldx #"."
	lda :c
	cmp #$20
	blt :dot
	cmp #$80
	bcs :dot
	ora #$80
	tax
:dot
	txa
	ldy :screen2
	sta |8*3+4,y
	iny
	sty :screen2


	dec :count
	bne :one_byte


	ldx :row
	inx
	inx
	stx :row
	cpx #20*2
	bcc :one_row

	plp
	rts


hex	asc "0123456789abcdef"



ssc_registers
	debug ssc_registers
*
* print SSC read registers.  read reg 8 (incoming data byte) is skipped.
*
*

*SCCBREG		equ $c038
*SCCAREG		equ $c039
*SCCBDATA	equ $c03a
*SCCADATA	equ $c03b

* read everything at once.

	php
	sep #$34 ; short m/x, ints off
	lda #0
	xba
*	sei
	ldx #0
	lda SCCAREG ; sync
	lda SCCBREG ; sync

	stx SCCAREG
	lda SCCAREG
	sta ssc_data+0
	stx SCCBREG
	lda SCCBREG
	sta ssc_data+1

	inx ;1

	stx SCCAREG
	lda SCCAREG
	sta ssc_data+2
	stx SCCBREG
	lda SCCBREG
	sta ssc_data+3

	inx ;2

	stx SCCAREG
	lda SCCAREG
	sta ssc_data+4
	stx SCCBREG
	lda SCCBREG
	sta ssc_data+5

	inx ;3

	stx SCCAREG
	lda SCCAREG
	sta ssc_data+6
	stx SCCBREG
	lda SCCBREG
	sta ssc_data+7


	ldx #10 ; 10

	stx SCCAREG
	lda SCCAREG
	sta ssc_data+8
	stx SCCBREG
	lda SCCBREG
	sta ssc_data+9


	ldx #12 ; 12

	stx SCCAREG
	lda SCCAREG
	sta ssc_data+10
	stx SCCBREG
	lda SCCBREG
	sta ssc_data+11

	inx ; 13

	stx SCCAREG
	lda SCCAREG
	sta ssc_data+12
	stx SCCBREG
	lda SCCBREG
	sta ssc_data+13

	ldx #15 ; 15

	stx SCCAREG
	lda SCCAREG
	sta ssc_data+14
	stx SCCBREG
	lda SCCBREG
	sta ssc_data+15


	cli
	rep #$10 ; long x
	mx %10
	jsr rr0
	jsr rr1
	jsr rr2
	jsr rr3 ; only exists in channel A.
	jsr rr10
	jsr rr12 ; baud low
*	jsr rr13 ; baud high
	jsr rr15
	plp
	rts

ssc_data	ds 16

rr0
	mx %10
	ldy #line_5+4
	ldx #:str
	jsr print_xy_str
	lda ssc_data+0
	jsr print_binary
	iny
	iny
	lda ssc_data+1
	jmp print_binary

:str	asc "RR 0:  ",00

rr1
	mx %10
	ldy #line_6+4
	ldx #:str
	jsr print_xy_str
	lda ssc_data+2
	jsr print_binary
	iny
	iny
	lda ssc_data+3
	jmp print_binary

:str	asc "RR 1:  ",00

rr2
	mx %10
	ldy #line_7+4
	ldx #:str
	jsr print_xy_str
	lda ssc_data+4
	jsr print_binary
	iny
	iny
	lda ssc_data+5
	jmp print_binary

:str	asc "RR 2:  ",00

rr3
	mx %10
	ldy #line_8+4
	ldx #:str
	jsr print_xy_str
	lda ssc_data+6
	jsr print_binary
	iny
	iny
	lda ssc_data+7
	jmp print_binary

:str	asc "RR 3:  ",00

rr10
	mx %10
	ldy #line_9+4
	ldx #:str
	jsr print_xy_str
	lda ssc_data+8
	jsr print_binary
	iny
	iny
	lda ssc_data+9
	jmp print_binary

:str	asc "RR 10: ",00

* 12/13 are baud

rr12
	mx %10
	ldy #line_10+4
	ldx #:str
	jsr print_xy_str

	iny
	iny
	iny
	iny

	lda ssc_data+12
	jsr print_hex
	lda ssc_data+10
	jsr print_hex

	iny
	iny
	iny
	iny
	iny
	iny

	lda ssc_data+13
	jsr print_hex
	lda ssc_data+11
	jmp print_hex


:str	asc "RR 12: ",00


rr15
	mx %10
	ldy #line_11+4
	ldx #:str
	jsr print_xy_str

	lda ssc_data+14
	jsr print_binary
	iny
	iny
	lda ssc_data+15
	jmp print_binary

:str	asc "RR 15: ",00





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
