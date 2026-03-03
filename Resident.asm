LOCALS
.model tiny
.code

org 100h

;----------------------------------------------------------
; сейчас сделаем так, что бы при вызове нашей программы
; появлялась рамочка, внутри которой отображались регистры
; ax, bx, cx и dx
;----------------------------------------------------------
Start:  xor ax, ax
        mov es, ax
        mov bx, 4*08h

        ; Запоминаем адрес 8ого прерывания
        mov ax, es: word ptr [bx]
        mov cs: word ptr Old_08, ax          ; Запоминаем смещение
        mov ax, es: word ptr [bx+2]
        mov cs: word ptr Old_08+2, ax        ; Запоминаем сегмент

        ; Заменяем 08 прерывание на New08
        cli
        mov es: word ptr [bx], offset New08
        mov es: word ptr [bx+2], cs
        sti

        xor ax, ax
        mov es, ax
        mov bx, 4*09h

        ; Запоминаем адрес 9ого прерывания
        mov ax, es: word ptr [bx]
        mov cs: word ptr Old_09, ax          ; Запоминаем смещение
        mov ax, es: word ptr [bx+2]
        mov cs: word ptr Old_09+2, ax        ; Запоминаем сегмент

        ; Заменяем 08 прерывание на New09
        cli
        mov es: word ptr [bx], offset New09
        mov es: word ptr [bx+2], cs
        sti

        ; Завершаем программу оставляя ее в памяти (резидент)
        mov dx, offset EOP
        int 27h

New08   proc
        ; Вызываем стандартное прерывание 08h
        pushf                   ; Сохраняем так как call этого не делает, а в конце стандартного обработчика стоит iret
        call dword ptr cs:[Old_08]

        cmp cs: byte ptr [R_FLAG], 1
        jne @@EOI

        ; Здесь можно будет творить что захотим


@@EOI:  iret
New08   endp



New09   proc
        ; Считываем скан код вводимого символа и сохраняем в стеке перед вызовом стандартного прерывания
        in al, 60h
        cmp al, 1Dh     ; ScanCode(Нажатие    Ctrl)
        jne  @@NOT_C
            mov cs: byte ptr [CTRL_FLAG], 1
            jmp @@HK
@@NOT_C:cmp al, 21h     ; ScanCode(Нажатие       F)
        jne @@NOT_F
            cmp cs: byte ptr [CTRL_FLAG], 1
            jne NOT_HK
                mov cs: byte ptr [F_FLAG], 1
                jmp @@HK

NOT_HK: mov cs: byte ptr [CTRL_FLAG], 0
        mov cs: byte ptr [F_FLAG], 0

        ; Вызываем стандартное прерывание 08h
        pushf                   ; Сохраняем так как call этого не делает, а в конце стандартного обработчика стоит iret
        call dword ptr cs:[Old_09]

        jmp @@EOI

@@HK:   mov al, cs: byte ptr [CTRL_FLAG]
        and al, cs: byte ptr [F_FLAG]
        cmp al, 1
        jne NOT_HK

        ; Change RenderingFlag
        xor cs: byte ptr [R_FLAG], 1

@@EOI:  iret
New09   endp


.data

R_FLAG      db 0 ; Rendering Flag
F_FLAG      db 0
CTRL_FLAG   db 0
Old_08      dd 1 dup(?)
Old_09      dd 1 dup(?)

EOP:

end Start
