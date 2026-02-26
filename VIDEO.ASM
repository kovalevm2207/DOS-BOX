.model tiny
.code

org 0100h

STRING_COLOR	 equ 10001110b
BACKGROUND_COLOR equ 01000000b
FRAME_COLOR      equ 01001110b
L_U_CORNER		 equ 0d5h
L_D_CORNER		 equ 0d4h
R_U_CORNER	     equ 0b8h
R_D_CORNER	  	 equ 0beh
FRAME_T 		 equ 0cdh
FRAME_D 		 equ 0cdh
FRAME_L			 equ 0b3h
FRAME_R          equ 0b3h

; dx - от левого края до начала строки
; si - длина строки
; ri - место в видео памяти
; cx - счетчики
; ax - обычно возвращаемое значение

Start:			; надо установить сегментный регистр для
				; записи в видеопамять (text)
				mov ax, 0b800h ; кладем сначала ax, потому что
						       ; нельзя сразу класть в es
				mov es, ax	   ; записываем значение в es

				call ClearConsol  		; очистили консоль

				mov si, [80h]			; адрес строки

				call SetBackground		; сделали фон
				call DrawFrame			; нарисовали рамку
				;call WriteStr			; вывели строчку

EndString:		mov ax, 4c00h
				int 21h


;	  ________________ просто название функции
;	 /             ___ показывает начало функции
;   /             /		(можно опустить)
ClearConsol	proc
				mov al, ' '			; символ  |
				mov ah, 00001000b	; атрибут | что
				mov cx, 80d*25d		; сколько (для rep)
				mov di, 0h			; смещение от es
				cld				; сброс флага (DF = 0)
								; чтобы di++ & si++
								; антоним: std
				rep stosw		;
				;\	   \____ выводит слово и di++ & si++
				; \_________ для  повтора cx раз
				ret
ClearConsol		endp ; строка показывает конец объявления
				     ; функции (можно опустить, но с ними
					 ; код более понятный)

SetBackground   proc
				; Вычислим смещение от начала строчки (dl)
				xor dx, dx
				mov dx, si 		  ; dx = SL
				shr dx, 1h		  ; dx = dx%2 (dx = SL%2)
				sal dx, 1h		  ; dx = dx*2 (dx = (SL%2)*2 )
				neg dx			  ; dx = -dx  (dx = -(SL%2)*2 )
				add dx, 68d		  ; dx += 73  (dx = 70-(SL%2)*2 )

				cld

				xor bx, bx
	Lines:		; Устанавливаем значение смещения в видео памяти
				mov ax, 160d		; ax = 160
				mul bl				; ax = al*bx  (ax = 160*bx)
				add ax, 7d*160d		; ax += 7*160 (ax = 160*(bx+7) )
				add ax, dx			; ax += dx    (ax = 160*(bx+7)+dx)
				mov di, ax			; di = ax

				; Устанавливаем символ и атрибут
				mov al, ' '
				mov ah, BACKGROUND_COLOR

				; cx = StrLength + 10 - количество повторов (длина фона рамки)
				mov cx, si+12d

				rep stosw

				inc bx
				cmp bx, 12d
				jl Lines

				add dx, 12d
				ret
SetBackground endp

DrawFrame proc
			; рисуем левый верхний угол
			mov di, 160d*9d-4d     ;|
			add di, dx             ;| устанавливаем начально смещение
			mov es: byte ptr [di],   L_U_CORNER
			mov es: byte ptr [di+1], FRAME_COLOR

			; рисуем верхнюю грань
			mov al, FRAME_T     ;| установили символ
 			mov ah, FRAME_COLOR ;| и атрибут
			mov cx, si+2 ; количество повторений
			add di, 2d			; обновляем смещение
			cld					; выбираем ++
			rep stosw

			; рисуем правый верхний угол
			mov es: byte ptr [di],   R_U_CORNER
			mov es: byte ptr [di+1], FRAME_COLOR

			; Рисуем столбики
			mov si, 160d*14d+si+4d	;| устанавливаем точку
			add si, dx						;| для прерывания
	Column:
			add di, 160-(si+3)*2		; переходим на следующий левый столбец
			mov es: byte ptr [di],   FRAME_L
			mov es: byte ptr [di+1], FRAME_COLOR

			add di, (si+3)*2			; переходим к правому столбцу
			mov es: byte ptr [di],   FRAME_R
			mov es: byte ptr [di+1], FRAME_COLOR

			cmp di, si
			jb  Column

			; рисуем левый нижний угол
			add di, 160-(si+3)*2   	; обновляем смещение
			mov es: byte ptr [di],   L_D_CORNER
			mov es: byte ptr [di+1], FRAME_COLOR

			; рисуем нижнюю грань
			mov al, FRAME_T     ;| установили символ
 			mov ah, FRAME_COLOR ;| и атрибут
			mov cx, si+2 ; количество повторений
			add di, 2d			; обновляем смещение
			cld					; выбираем ++
			rep stosw

			; рисуем правый нижний угол
			mov es: byte ptr [di],   R_D_CORNER
			mov es: byte ptr [di+1], FRAME_COLOR

			ret
DrawFrame endp

WriteStr proc

						;	_____  оператор взятия адреса
						;  /       по метке
				mov di, offset String ; присвоили si указатель
									  ; на строчку
				xor bx, bx ; на всякий случай обнулили bx
						   ;___|_0__1_|
						   ; 0 | 0  1 |
						   ; 1 | 1  0 |

StartString:	cmp bx, StrLength*2 ; устанавливает флаги анализируя
									; bx - StrLength*2
				jge	EndString		; SF = OF = 0 => jge
									;  \    \__ Overflow Flag (sign)
									;   \______ Sign Flag (см. ст. бит у )

				; хочу положить в ячейку видеопамяти символ
				; этот символ можно получить взяв значение по di
					;		______________ показывает что по этому адресу мы должны взять
					;		|              что-то длиной в 1 байт
					;		|	   _______ Скобки квадратные чтобы взять значение по адресу
					;   ____|___  /  /
				mov al, byte ptr [di] ; и положив его в регистр al

				add bx, dx 	; смещаем bx на нужную величину
				;	  _____________ нужно чтобы писали в другой сегмент памяти а не в базовый DS
				;    /
				mov es: byte ptr [160d*12+bx],     al
				mov es: byte ptr [160d*12+bx+01d], STRING_COLOR

				sub bx, dx ; возвращаем обратно bx, для корректной работы цикла

				add bx, 02d ; Увеличиваем счетчики
				inc di

				jmp StartString
EndString:		ret
WriteStr	endp

.data

String			db "FUCKING FRAME DONE!"
StrLength		equ $ - String
				;   \____ Текущий адрес (сразу после строчки)

end Start
