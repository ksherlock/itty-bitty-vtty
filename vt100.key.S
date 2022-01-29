
	lst off
	rel
	xc
	xc

	use vt.equ
	use apple2gs.equ
	use debug

	mx %11

*	ext dispatch
	ext write_modem


kmShift		equ %0000_0001
kmControl	equ %0000_0010
kmCapsLock	equ %0000_0100
kmRepeat	equ %0000_1000
kmKeypad	equ %0001_0000
kmUpdateMod	equ %0010_0000
kmOption	equ %0100_0000
kmCommand	equ %1000_0000

dispatch
	jmp write_modem

keypress ent
	debug keypress
	lda KBD
	bmi :key
:rts	rts
:key
	and #$7f
	sta key
	lda KEYMOD
	sta mod
	sta KEYSTROBE

* if DECARM is clear, skip repeat characters.
	bit DECARM
	bpl :arm
	bit #kmRepeat
	bne :rts
:arm


	bit #kmOption!kmCommand
	bne command

	bit #kmKeypad
	bne keypad
	bit #kmControl
	bne :ctrl

	lda key
	cmp #' '
	bcs :notctrl

* control char w/o control bit.
* ie, arrow key / return / tab
* no cmp / sbc needed
	asl
	tax
	lsr ; restore
	jmp (special,x)

:ctrl
	lda key
	and #$1f ; control-space should generate 0, not $20.
	bra :send

:notctrl
	cmp #$7f ; delete - special case 
	bne :send
	lda #$08
:send	jmp dispatch

command ; or option

* apple-return -> linefeed
* apple-backspace -> delete
	

	lda key
	cmp #$7f
	beq :bs
	cmp #$0d
	beq :lf

	cmp #:MIN
	blt :rts
	cmp #:MAX+1
	bcs :rts
	sec
	sbc #:MIN
	asl
	tax
	jmp (:table,x)

:rts	rts


:MIN	equ 49
:MAX	equ 52

:bs	jmp dispatch ; 
:lf	lda #$0a
	jmp dispatch


:table
	dw pf1	; 1
	dw pf2	; 2
	dw pf3	; 3
	dw pf4	; 4



keypad
* todo - keypad enters honors LNM?

	lda key
	cmp #:MIN
	blt :rts
	cmp #:MAX+1
	bcs :rts
	sec
	sbc #:MIN
	asl
	tax
	jmp (:table,x)

:rts	rts

:MIN	equ 13
:MAX	equ 61
:table
	dw enter	; ^M Enter -> \r, ESC ? M
	dw :rts		; ^N
	dw :rts		; ^O
	dw :rts		; ^P
	dw :rts		; ^Q
	dw :rts		; ^R
	dw :rts		; ^S
	dw :rts		; ^T
	dw :rts		; ^U
	dw :rts		; ^V
	dw :rts		; ^W
	dw :rts		; ^X
	dw :rts		; ^Y
	dw :rts		; ^Z
	dw pf1		; ^[ PF1 -> ESC P
	dw :rts		; ^\
	dw :rts		; ^]
	dw :rts		; ^^
	dw :rts		; ^_
	dw :rts		;  
	dw :rts		; !
	dw :rts		; "
	dw :rts		; #
	dw :rts		; $
	dw :rts		; %
	dw :rts		; &
	dw :rts		; '
	dw :rts		; (
	dw :rts		; )
	dw pf4		; *
	dw comma	; +
	dw :rts		; ,
	dw dash	; -
	dw dot		; .
	dw pf3		; / PF3 -> ESC R
	dw digit	; 0
	dw digit	; 1
	dw digit	; 2
	dw digit	; 3
	dw digit	; 4
	dw digit	; 5
	dw digit	; 6
	dw digit	; 7
	dw digit	; 8
	dw digit	; 9
	dw $0		; :
	dw $0		; ;
	dw $0		; <
	dw pf2		; = PF2 -> ESC Q


enter
	bit DECKPAM
	bmi :alt
	brl cr
:alt
	jmp ?O

comma
* iigs keyboard is a +
	lda #','
	sta key
	bit DECKPAM
	bmi :alt
	jmp dispatch
:alt
	jmp ?O
dot
	lda key
	bit DECKPAM
	bmi :alt
	jmp dispatch
:alt
	jmp ?O

dash
	lda key
	bit DECKPAM
	bmi :alt
	jmp dispatch
:alt
	jmp ?O

digit
	lda key
	bit DECKPAM
	bmi :alt
	jmp dispatch
:alt

*	jmp ?O
* drop through

?O
* send ESC ? key if vt52, ESC O key if vt100

	lda #ESC
	jsr dispatch
	bit DECANM
	bpl :vt52
	lda #'O'
	jsr dispatch
	lda key
	ora #$40
	jmp dispatch
:vt52
	lda #'?'
	jsr dispatch
	lda key
	ora #$40
	jmp dispatch


pf1
	lda #'P'
	sta key
	bra pf
pf2
	lda #'Q'
	sta key
	bra pf
pf3
	lda #'R'
	sta key
	bra pf
pf4
	lda #'S'
	sta key
pf
	lda #ESC
	jsr dispatch
	bit DECANM
	bpl :vt52
	lda #'O'
	jsr dispatch
:vt52	lda key
	jmp dispatch


special
	dw dispatch		; ^@
	dw dispatch		; ^A
	dw dispatch		; ^B
	dw dispatch		; ^C
	dw dispatch		; ^D
	dw dispatch		; ^E
	dw dispatch		; ^F
	dw dispatch		; ^G
	dw left			; ^H
	dw dispatch		; ^I - tab
	dw down			; ^J
	dw up			; ^K
	dw dispatch		; ^L
	dw cr			; ^M
	dw dispatch		; ^N
	dw dispatch		; ^O
	dw dispatch		; ^P
	dw dispatch		; ^Q
	dw dispatch		; ^R
	dw dispatch		; ^S
	dw dispatch		; ^T
	dw right		; ^U
	dw dispatch		; ^V
	dw dispatch		; ^W
	dw dispatch		; ^X
	dw dispatch		; ^Y
	dw dispatch		; ^Z
	dw dispatch		; ^[
	dw dispatch		; ^\
	dw dispatch		; ^]
	dw dispatch		; ^^
	dw dispatch		; ^_



cr
* Return sends CR or CR + LF (LNM)
	bit LNM
	bmi :crlf
	lda #$0d
	jmp dispatch

:crlf
	lda #$0d
	jsr dispatch
	lda #$0a
	jmp dispatch


left
	lda #'D'
	bra arrow
right
	lda #'C'
	bra arrow
up
	lda #'A'
	bra arrow
down
	lda #'B'
* drop through
arrow
* actual character generated depends on DECANM and DECCKM

	sta key
	lda #ESC
	jsr dispatch

	bit DECANM
	bpl :vt52
	bit DECCKM
	bmi :cursor

	lda #'['
	jsr dispatch
	lda key
	jmp dispatch

:cursor
	lda #'O'
	jsr dispatch
* drop through.
:vt52
	lda key
	jmp dispatch

	sav vt100.key.L
