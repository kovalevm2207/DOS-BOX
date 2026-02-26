.model tiny
.code

org 100h

TAB		equ 9h
NEWLINE		equ 0dh, 0ah
EOF		equ '$'

Start:		mov ah, 9h
		mov dx, offset Hello
		int 21h				; Say hello user
			
GetAns:		mov dx, offset Question
		int 21h  			; Give a question for user
		
		mov ah, 1h						 
		int 21h				; Scan user answer
		
		mov ah, 9h

		cmp al, '1'	
		je Cat

		cmp al, '2'
		je Dog

		cmp al, '3'
		je Bird

		mov dx, offset Incorrect
		int 21h
		jmp GetAns		

Cat:		mov dx, offset CatAns
		jmp EndProgram

Dog: 		mov dx, offset DogAns
		jmp EndProgram
	
Bird:		mov dx, offset BirdAns

EndProgram:	int 21h

		mov ah, 4ch
		int 21h				; end prgm

.data
Hello:		db NEWLINE
		db TAB, '     		 Hello user!', NEWLINE
		db TAB, 'I want to ask you "what is your favorite animal?"', NEWLINE
		db TAB, 'Is it:',    NEWLINE	
		db TAB, '1) cat?',   NEWLINE
		db TAB, '2) dog?',   NEWLINE
		db TAB, '3) bird?',NEWLINE, EOF

Question:	db NEWLINE
		db TAB, 'Please write the answer (numder of the variant):', NEWLINE, EOF
		db NEWLINE,TAB, TAB, TAB, EOF

CatAns: 	db NEWLINE
		db TAB, 'You must go and lay POLTORASHKA!!!'
		db NEWLINE, EOF

DogAns:		db NEWLINE
		db TAB, "I do't know you... POLTORASHKA - the BEST!"
		db NEWLINE, EOF

BirdAns:	db NEWLINE
		db TAB, "AHAHAHHAH! Is it joke?) POLTORASHKA - the BEST!"
		db NEWLINE, EOF

Incorrect:     	db NEWLINE 
		db TAB, "Are you stupit? You can use only 1, 2 or 3!"
		db NEWLINE, EOF

end Start