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
        ; Устанавливаем флаг, показывающий срабатывание таймера
        mov cs: byte ptr [FLAG], 1

        ; Вызываем стандартное прерывание 08h
        pushf                   ; Сохраняем так как call этого не делает, а в конце стандартного обработчика стоит iret
        call dword ptr cs:[Old_08]

        iret
New08   endp

New09   proc
        ; Вызываем стандартное прерывание 08h
        pushf                   ; Сохраняем так как call этого не делает, а в конце стандартного обработчика стоит iret
        call dword ptr cs:[Old_09]

        cmp cs: byte ptr [FLAG], 1
        jne @@EOI

        ; Сбрасываем флаг
        mov cs: byte ptr [FLAG], 0

        ; Здесь можно будет творить что захотим

@@EOI:  iret
New09   endp


.data

FLAG    db 0
Old_08   dd 1 dup(?)
Old_09   dd 1 dup(?)

EOP:

end Start
