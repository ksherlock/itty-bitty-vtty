


vt100
	mx %11
	and #$7f
	cmp #' '
	bcs :notctrl
	asl
	tax
	jmp (ctrl,x)
:notctrl
	ldx state
	jmp (:state_table,x)



:state_table
	ext vt52_esc,vt52_dca
	ext vt100_esc,vt100_csi,vt100_csi_2
	ext vt100_esc_pound,vt100_esc_lparen,vt100_esc_rparen

	dw char
	dw vt52_esc
	dw vt52_dca
	dw char
	dw vt100_esc
	dw vt100_csi
	dw vt100_csi_2
	dw vt100_esc_pound
	dw vt100_esc_lparen
	dw vt100_esc_rparen





vt100_csi_bad ent
	cmp #'@'
	blt :rts
	ldx #st_vt100
	stx state
:rts	rts




esc_csi
	stz pcount
	stz params
	stz params+1
	stz csi_private
	lda #st_csi
	sta state
	rts


csi
	inc state
	inc state
	cmp #'?'
	bne csi0
	lda #$80
	sta csi_private
	rts

csi0
	cmp #';'
	beq :semi
	cmp #'0'
	bcc csi_final
	cmp #'9'+1
	bcs csi_final
:num
	and #$0f ; 0-9
	tay ; save
	ldx pcount
	lda params,x
	asl ; x 2
	sta params,x
	asl ; x 4
	asl ; x 8
	clc
	adc params,x
	sta params,x
	tya
	clc
	adc params,x
	sta params,x
	rts


:semi
	ldx pcount
	inx
	cpx #MAX_PCOUNT
	bcs :srts
	stx pcount
	stz params,x

:srts
	rts


csi_final
* c, h, l have private modes.
	bit csi_private
	bmi :priv

	cmp #:MIN_FINAL
	bcc :rts
	cmp #:MAX_FINAL+1
	bcs :rts
	asl
	tax
	jmp (:table,x)
:rts	rts

:priv
	cmp #:MIN_FINAL_PRIV
	bcc :rts
	cmp #:MAX_FINAL_PRIV+1
	bcs :rts
	asl
	tax
	jmp (:table_priv,x)


csi
*
* ESC [ encountered.
*
* ? -> DEC private
* 0-9 -> parameter value
* ; parameter delim
* other - final character.

	cmp #'0'
	blt :notnum
	cmp #'9'+1
	bge :notnum

	sep #$30
	and #$0f
	tay
	ldx pcount
	lda parms,x
	asl
	pha
	asl
	asl
	clc
	adc 1,s
	sta 1,s
	tya
	adc 1,s
	ply
	sta parms,x
	sep #$30
]rts	rts
:notnum
	cmp #';'
	bne :notsemi
	ldx pcount
	cpx #MAXPCOUNT
	bge ]rts
	inx
	stx pcount
	stz parms,
	stz parms+1,x
]rts	rts
:notsemi
	cmp #'?'
	bne :final
	sta ptype
	rts
:final