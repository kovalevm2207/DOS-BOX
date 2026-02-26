.model tiny				
.code					

org 100h				; Skip PSP (Program Segment Pointer)	
	
TAB  		equ 9h
NEWLINE		equ 0dh, 0ah
EOF		equ '$'

start:		mov ah, 9	
		mov dx, offset string
		int 21h

		mov ax, 4c00h
		int 21h

.data
string:		db NEWLINE
		db TAB, TAB, 'At IN! Attention!', NEWLINE
		db TAB, 'Why are you scared?))) it is just joke'
		db NEWLINE, EOF

end start
