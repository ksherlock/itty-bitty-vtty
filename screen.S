
	rel
	mx %11

	ent erase_line
	ent erase_line_0
	ent erase_line_1
	ent erase_line_2

erase_line
; a = 0 - erase x - eol (inclusive)
; a = 1 - erase 0 - x (inclusive)
; a = 2 - erase 0 - eol
	cmp #2
	bcs :rts
	asl
	tax
	jmp (:table,x)
:rts rts

:table
	dw erase_line_0
	dw erase_line_1
	dw erase_line_2

erase_line_2
* erase entire line.
	php
	rep #$30
	ldy #38
	lda #"  "
:loop
	sta [text01],y
	sta (text00),y
	dey
	dey
	bpl :loop
	plp
	rts

	mx %11

erase_line_0
* erase to eol

	lda x
	lsr
	tay
	lda #" "
	bcs :half
:loop
	sta [text01],y
:half	sta (text00),y
	iny
	cpy #40
	bcc :loop
	rts

erase_line_1
* erase to x (inclusive)

	lda x
	lsr
	tay
	lda #" "
	bcc :half

:loop
	sta (text00),y
:half	sta [text01],y
	dey
	bpl :loop
	rts


erase_screen	ent
; a = 0 - erase [cursor, end] (inclusive)
; a = 1 - erase [start, cursor] (inclusive)
; a = 2 - erase [start, end]
	cmp #2
	bcs :rts
	asl
	tax
	jmp (:table,x)
:rts rts

:table
	dw erase_screen_0
	dw erase_screen_1
	dw erase_screen_2	

erase_screen_2	ent
* erase the entire screen.
	php
	rep #$30
	lda #"  " ; high bit set.

c00	cc $0400
c01	cc $0480
c02	cc $0500
c03	cc $0580
c04	cc $0600
c05	cc $0680
c06	cc $0700
c07	cc $0780
c08	cc $0428
c09	cc $04a8
c10	cc $0528
c11	cc $05a8
c12	cc $0628
c13	cc $06a8
c14	cc $0728
c15	cc $07a8
c16	cc $0450
c17	cc $04d0
c18	cc $0550
c19	cc $05d0
c20	cc $0650
c21	cc $06d0
c22	cc $0750
c23	cc $07d0
	plp
	rts

	mx %11

erase_screen_0	ent
* erase from cursor to the end.
	mx %11
	ldx #0 ; for jmp (,x)
	lda x
	ora y
	beq :all

	lda x
	beq :x0
	jsr erase_line_0
	lda y
	inc
	bra :x1
:x0
	lda y
:x1	cmp #23
	bcs :rts
	asl
	tax
:all	php ; clear_table will plp.
	rep #$30
	lda #"  "
	jmp (clear_table,x)

:rts	rts


erase_screen_1	ent
* erase from start to cursor.
	jsr erase_line_1
	lda y
	bne :ok
	rts
:ok
	php
	rep #$30
	lda y
	dey
	asl
	tax
	lda #"  "
	jmp (:clear_table,x)
:clear_table


c23	cc $07d0
c22	cc $0750
c21	cc $06d0
c20	cc $0650
c19	cc $05d0
c18	cc $0550
c17	cc $04d0
c16	cc $0450
c15	cc $07a8
c14	cc $0728
c13	cc $06a8
c12	cc $0628
c11	cc $05a8
c10	cc $0528
c09	cc $04a8
c08	cc $0428
c07	cc $0780
c06	cc $0700
c05	cc $0680
c04	cc $0600
c03	cc $0580
c02	cc $0500
c01	cc $0480
c00	cc $0400
	plp
	rts