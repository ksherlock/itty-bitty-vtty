*
* boot block.
*
* loaded at $0800

	xc
	xc
	rel

SLOT	equ $00
CMD	equ $42
UNIT	equ $43
BUFFER	equ $44
BLOCK	equ $46

	ext init
boot
	mx %11

	db $01 ; prodos boot id

* slot 5 = x = $50, a = $3178
* slot 6 = x = $60, a = $8401 
*	stx :unit
*	txa
*	lsr
*	lsr
*	lsr
*	lsr
*	ora #$c0


	stx UNIT
	txa
	lsr
	lsr
	lsr
	lsr
	ora #$c0
	sta :prodos+2

	stz SLOT
	sta SLOT+1

	ldy #1
	lda (SLOT),y
	cmp #$20
	bne noboot
	ldy #3
	lda (SLOT),y
	bne noboot
	ldy #5
	lda (SLOT),y
	cmp #$03
	bne noboot

	ldy #$ff
	lda (SLOT),y
	sta :prodos+1


	lda #1
	sta CMD
	sta BLOCK
	stz BLOCK+1
	stz BUFFER
	lda #$a0 ; $0800+512
	sta BUFFER+1

:read
	jsr :prodos ; block 1
	bcs noboot

	inc BLOCK
	inc BUFFER+1
	inc BUFFER+1
	lda BLOCK
	cmp #6
	bcc :read
	bra :ok

:prodos jmp $0000


:ok

	clc
	xce
	cli

	jsr init

noboot
:loop	wai
	bra :loop




	sav boot.L