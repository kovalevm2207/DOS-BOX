.model tiny
.code

org 100h

Start:
        mov bx, 0BBBBh
        mov cx, 0CCCCh
        mov dx, 0DDDDh
        mov si, 01111h
        mov di, 02222h
        mov bp, 03333h
        mov ax, 04444h
        mov ds, ax
        mov ax, 05555h
        mov es, ax
        mov ax, 0AAAAh

inf_cycle:
            jmp inf_cycle

        mov ah, 04ch
        int 21h
End Start
