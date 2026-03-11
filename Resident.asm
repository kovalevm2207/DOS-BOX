LOCALS
.model tiny

REG_NUM         equ 13
STR_LEN         equ 7

save_int MACRO int_name
        mov ax, es: word ptr [bx]
        mov cs: word ptr int_name, ax          ; Запоминаем смещение
        mov ax, es: word ptr [bx+2]
        mov cs: word ptr int_name+2, ax        ; Запоминаем сегмент
ENDM

change_int_on MACRO int_name
        cli
        mov es: word ptr [bx], offset int_name
        mov es: word ptr [bx+2], cs
        sti
ENDM

;---------------------------------------------------------------------------------------
; New09: прерывание устанавливающее флаг R_FLAG в случае нажатия сочетания клавиш Ctrl+F
; Входные параметры: bp - указатель в памяти на место хранения отображаемого байта
;                    es:di - место в памяти, куда будет помещен результат
; Ожидаемое состояние: cs - сегмент с кодом программы Resident.asm
; Возвращаемое значение:
; Испорченные регистры: ax, bx, cx
;---------------------------------------------------------------------------------------
ShowWord MACRO
        LOCAL @@Next, @@Cond, @@Num
                mov bx, 0f000h              ; mask

                xor cx, cx
        @@Next:         mov ax, ss: word ptr [bp]   ; value
                        and ax, bx                  ; оставляем нужные четыре бита
                        shr bx, 04h                 ; меняем маску
                        mov cl, ch
                        neg cl
                        add cl, 3
                        shl cl, 2
                        shr ax, cl            ; сдвигаем данные

                        mov ah, cs: byte ptr [STRING_CLR]
                        cmp al, 09h
                        jbe @@Num
                                add al, 'A'-0ah
                                mov es: word ptr[di], ax
                                jmp @@Cond

                @@Num:  add al, '0'
                        mov es: word ptr[di], ax

                @@Cond: add di, 2
                        inc ch
                cmp ch, 04h
                jb @@Next
ENDM

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

        save_int Old_08
        change_int_on New08

        xor ax, ax
        mov es, ax
        mov bx, 4*09h

        save_int Old_09
        change_int_on New09

        ; Завершаем программу оставляя ее в памяти (резидент)
        mov dx, offset EOP
        int 27h

New08   proc    ; pushf     ; sp = real_sp - 2
                ; push ip   ; sp = real_sp - 4
                ; push cs   ; sp = real_sp - 6
        sub sp, 2           ; освобождаем места, для хранения sp => sp_save_ptr = real_sp - 6
        push ss es ds bp    ; sp = real_sp - 16 <----<----<-----<
        add sp, 10          ; sp = real_sp - 6 = sp_save_ptr    |
        mov bp, sp          ;                                   |
        add bp, 6           ; bp = real_sp                      ^
        push bp             ; sp = real_sp - 8                  |
        sub sp, 8           ; sp = real_sp - 16 --->---->---->--^
        push di si dx cx bx ax
        ; Вызываем стандартное прерывание 08h
        pushf                   ; Сохраняем так как call этого не делает, а в конце стандартного обработчика стоит iret
        call dword ptr cs:[Old_08]

        cmp cs: byte ptr [R_FLAG], 1
        jne @@N_HK

        ; update save_buf with result of compare draw_buf with v_ram

        mov ax, ds
        mov es, ax
        clc

        call DrawFrame  ; draw frame with registers in draw_buf
        call WriteStr

        ; drop draw_buf in vram
        jmp @@EOI

@@N_HK: cmp cs: byte ptr [PREV_R_F], 1
        jne @@EOI
                mov cs: byte ptr [PREV_R_F], 0
                ; drop save_buf in v_ram

@@EOI:  pop ax bx cx dx si di bp ds es ss sp
        sub sp, 6

        iret    ; pop cs
                ; pop ip
                ; popf
New08   endp

;----------------------------------------------------------------------------------------
; Описание: (DrawFrame) рисует рамку на нужном месте в видеопамяти
; Входные параметры: es = ds
;
; Возвращаемое значение: --//--
;
; Ожидаемое состояние: CF = 0
;
; Испорченные регистры: ax, cx, di
;----------------------------------------------------------------------------------------
DrawFrame proc
		mov di, offset DrawBuf
		mov al, cs: byte ptr [BACKGROUND_SYM]
		mov ah, cs: byte ptr [FRAME_CLR]
                mov cx, STR_LEN
		add cx, 8
                rep stosw

		xor bx, bx
    	@@Next:         inc bx
			mov cx, 2
			rep stosw

			cmp bx, 1
			je @@TOP1

				cmp bx, REG_NUM+2
				je @@DOWN1

                        mov al, cs: byte ptr [FRAME_L]
			jmp @@CNT1

		@@DOWN1:        mov al, cs: byte ptr [L_D_CORNER]
				jmp @@CNT1

		@@TOP1: mov al, cs: byte ptr [L_U_CORNER]

		@@CNT1: mov ah, cs: byte ptr [FRAME_CLR]
			mov es: word ptr [di], ax

			add di, 2

			cmp bx, 1
			je @@TOP2

				cmp bx, REG_NUM+2
				je @@DOWN2

					mov al, cs: byte ptr [BACKGROUND_SYM]
					jmp @@CNT2

	        @@DOWN2:mov al, cs: byte ptr [FRAME_D]
			jmp @@CNT2

	        @@TOP2: mov al, cs: byte ptr [FRAME_T]
			jmp @@CNT2

	     @@SubNext: jmp @@Next

		@@CNT2: mov cx, STR_LEN
			add cx, 2
			rep stosw

			cmp bx, 1
			je @@TOP3

				cmp bx,  REG_NUM+2
				je @@DOWN3

					mov al, cs: byte ptr [FRAME_R]
					jmp @@CNT3

	        @@DOWN3:mov al, cs: byte ptr [R_D_CORNER]
			jmp @@CNT3

	        @@TOP3: mov al, cs: byte ptr [R_U_CORNER]

		@@CNT3: mov es: word ptr [di], ax

			add di, 2
			mov al, cs: byte ptr [BACKGROUND_SYM]
			mov cx, 2
			rep stosw

		cmp bx,  REG_NUM+2
		jb @@SubNext

		mov al, cs: byte ptr [BACKGROUND_SYM]
		mov cx, STR_LEN
		add cx, 8
		rep stosw

                ret
DrawFrame endp

;-----------------------------------------------------------------------------------------
; Описание: по центру экрана выводит строчку с соответствующим фоном
;
; Входные параметры: es = ds
;
; Возвращаемое значение: --//--
;
; Ожидаемое состояние: CF = 0
;
; Испорченные регистры: ax bx cx dx bp di si
;-----------------------------------------------------------------------------------------
WriteStr proc
                mov di, offset DrawBuffer
                add di, (4+STR_LEN+4)*2+4       ; устанавливаем смещение для первого символа строки

                mov si, offset REG_NAMES
                xor dx, dx              ; - counter

                mov bp, sp
                add bp, 2               ; skip ret ptr
        @@Next:         mov ah, cs: byte ptr [STRING_CLR]
                        mov al, cs: byte ptr [si]
                        mov es: word ptr [di], ax

                        add di, 2
                        inc si

                        mov al, cs: byte ptr [si]
                        mov es: word ptr [di], ax

                        add di, 4
                        inc si

                        ShowWord
                        add bp, 2      ; go to the value of the next register's

                        add di, 8
                        inc dx
                cmp dx, REG_NUM
                jb @@Next

                ret
WriteStr endp

;---------------------------------------------------------------------------------------
; New09: прерывание устанавливающее флаг R_FLAG в случае нажатия сочетания клавиш Ctrl+F
; Входные параметры: --//--
; Ожидаемое состояние: cs - сегмент с кодом программы Resident.asm
;                      Old09 - содержит значение из таблицы прерываний на для исполняе-
;                      мого кода стандартного прерывания
; Возвращаемое значение: --//--
; Испорченные регистры: см. описание стандартного 09h DOS прерывания
;---------------------------------------------------------------------------------------
New09   proc
        push ax

        in  al, 60h
        cmp al, 1Dh     ; ScanCode(Нажатие    Ctrl)
        jne  @@NOT_C
                mov cs: byte ptr [CTRL_FLAG], 1
                jmp @@CTRL
@@NOT_C:cmp al, 21h     ; ScanCode(Нажатие       F)
        jne @@N_HK
                jmp @@HK

@@N_HK: ; Вызываем стандартное прерывание 08h
        mov cs: byte ptr [CTRL_FLAG], 0

@@CTRL: pushf           ; Сохраняем так как call этого не делает, а в конце стандартного обработчика стоит iret
        call dword ptr cs:[Old_09]

        jmp @@EOI

@@HK:   cmp cs: byte ptr [CTRL_FLAG], 1
        jne @@N_HK

        ; Change RenderingFlag
        xor cs: byte ptr [R_FLAG], 1

        in   al, 60h
        mov  ah, al
        or   al, 80h
        out  61h, al
        xchg ah, al
        out  61h, al

        mov al, 20h
        out 20h, al

@@EOI:  pop ax
        iret
New09   endp


.data

;~~~~~~~~~~~FLAGS~~~~~~~~~~~
R_FLAG          db 0 ; Rendering Flag
PREV_R_F        db 0 ; Previous rendering flag value
CTRL_FLAG       db 0

;~~~~~~~~OLD~VECTORS~~~~~~~~
Old_08          dd 1 dup(0)
Old_09          dd 1 dup(0)

;~~~~~~~FRAME~SYMBOLS~~~~~~~
L_U_CORNER	db 0c9h
FRAME_T 	db 0cdh
R_U_CORNER	db 0bbh
FRAME_L		db 0bah
BACKGROUND_SYM  db 020h
FRAME_R         db 0bah
L_D_CORNER	db 0c8h
FRAME_D 	db 0cdh
R_D_CORNER	db 0bch

;~~~~~~~~~~COLORS~~~~~~~~~~~
FRAME_CLR       db 03fh
STRING_CLR      db 030h

;~~~~~~~~Registers~~~~~~~~~~
REG_NAMES       db 'ax', 'bx', 'cx', 'dx', 'si', 'di', 'bp', 'ds', 'es', 'ss', 'sp', 'ip', 'cs'

;~~~~~~~~~Buffers~~~~~~~~~~~
DrawBuf         db 2*(4+REG_NUM)*(8+STR_LEN) dup(0)
SaveBuf         db 2*(4+REG_NUM)*(8+STR_LEN) dup(0)

EOP:

end Start

; Еще понадобится:
;		mov di, STR_LEN
;		and di, 0fffeh
;		neg di
;		add di, 72d
;
;		mov ax, REG_NUM
;		inc ax
;		shr ax, 1
;		neg ax
;		add ax, 10d
;		mov bl, 160d
;		mul bl
;		add di, ax 	      ; 72-(dx//2)*2+160d*(10d-((si+1)//2)
;
