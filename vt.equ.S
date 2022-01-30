
	cas se


st_vt52		equ 0
st_vt52_esc	equ 2
st_vt52_dca	equ 4
st_vt100	equ 6
st_vt100_esc	equ 8
st_vt100_csi	equ 10
st_vt100_csi_2	equ 12
st_vt100_esc_pound	equ 14 ; #
st_vt100_esc_lparen	equ 16 ; (
st_vt100_esc_rparen	equ 18 ; )

st_vt100_esc_bad	equ 20
st_vt100_csi_bad	equ 22

ESC	equ $1b

DPAGE	equ $1f00

	dum 0
state	ds 2
x	ds 2
y	ds 2

DECTM	ds 2 ; top margin
DECBM	ds 2 ; bottom margin

LOCAL	ds 2 ; local mode
DECANM	ds 2 ; ansi/vt52
DECKPAM ds 2 ; alternate keypad
DECCKM	ds 2 ; cursor key modes
DECOM	ds 2 ; origin
DECSCNM ds 2 ; screen mode
DECAWM	ds 2 ; wrap
DECARM	ds 2 ; auto repeat


LNM	ds 2 ; new line
SGR	ds 2 ; graphics, bit 1 = bold, 4 = underscore, 5 = blink, 7 = inverse

* not supported

*CHARSET	ds 2 ; 
*GRAPHICS	ds 2 ; 

*DECCOLM ds 2 ; character per line (80/132)
*DECINLM ds 2 ; interlace
*DECSCLM ds 2 ; scroll mode

* DECDHL - double height line
* DECDWL - double width line


* parameters
MAX_PCOUNT	equ 8
pcount	ds	2
parms	ds	MAX_PCOUNT
pmod	ds	2

; scratch registers
r0	ds	2


cursor_saved_char ds 2 ; saved char under the cursor
cursor_base	ds 4
cursor_offset	ds 2
cursor_char	ds 2 ; cursor character
cursor_state	ds 2 ; on/off/disabled.

draw_inverse	ds 2 ; flag to draw inverse
erase_char	ds 2 ; clear character


* keypress data.
key		ds 2
mod		ds 2


* saved cursor
saved_x	ds 2
saved_y	ds 2
saved_decom ds 2
saved_sgr ds 2


* async read/write pointers.
*
read_q_head	ds 2
read_q_tail	ds 2
write_q_head	ds 2
write_q_tail	ds 2

master_id	ds 2

	do *>256
	err "too big"
	fin
	dend
