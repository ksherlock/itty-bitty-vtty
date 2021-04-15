*
* boot block.
*
* loaded at $0800
* relocates everything to $6000, loads extra blocks, and runs main.

	xc
	xc
	rel
*	org $0800

ORG	equ $6000
*MAX_BLOCK equ 6


SLOT	equ $00
CMD	equ $42
UNIT	equ $43
BUFFER	equ $44
BLOCK	equ $46

	ext main
	ext MAXBLOCKS
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
	ldy #END-boot
:cp	lda $0800,y ; boot,y
	sta ORG,y
	dey
	bne :cp
	jmp ORG+:entry-boot

:entry	stx UNIT
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


	lda #1 ; read block
	sta CMD
	sta BLOCK
	stz BLOCK+1
	stz BUFFER
	lda #>{ORG+512} ; $0800+512
	sta BUFFER+1

:read
	jsr :prodos ; block 1
	bcs noboot

	inc BLOCK
	inc BUFFER+1
	inc BUFFER+1
	lda BLOCK
	cmp #MAXBLOCKS
	bcc :read
	bra :ok

:prodos jmp $0000


:ok
	jmp main

noboot
	ldx #0
:cout	lda :str,x
	beq :wai
	jsr $fded
	inx
	bra :cout

:wai	wai
	bra :wai

:str	asc "** BOOT ERROR **",00

END
	err *-boot>$ff
* fill to end of block since only 255 bytes relocated.
	ds boot+512-*

	sav boot.L