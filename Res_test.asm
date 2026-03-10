.model tiny
.code

org 100h

Start:
        mov ax, 0AAAAh
        mov bx, 0BBBBh
        mov cx, 0CCCCh
        mov dx, 0DDDDh

        mov ah, 07h
        int 21h

        mov ah, 04ch
        int 21h
End Start
