LOCALS
.model tiny

;~~~~~~~CONSTANTS~~~~~~~
NL	        equ 0dh, 0ah
EOS	        equ '$'
STR_NUM         equ 1

;---------------------------------------------------------------------------------------
; PrintStr: выводит на экран строчку из .data, оканчивающуюся '$'
; Входные параметры: StrName - имя метки строки
; Ожидаемое состояние: ds - сегмент с данными программы
; Возвращаемое значение: --//--
; Испорченные регистры: ah, dx
;---------------------------------------------------------------------------------------
PrintStr        MACRO   StrName
        mov     ah, 09h
        mov     dx, offset StrName
        int     21h
ENDM

;---------------------------------------------------------------------------------------
; CRC16: хеш-функция
; Входные параметры: SI - начало строки с данными
; Ожидаемое состояние:
; Возвращаемое значение: bx
; Испорченные регистры:
;---------------------------------------------------------------------------------------
HashFunc           MACRO
        LOCAL   @@Next

        xor     ax, ax
        xor     bx, bx
        mov     cx, 1

@@Next:         mov     al, ds: byte ptr [si]
                mul     cx

                add     bx, ax

                inc     si
                inc     cx

        cmp     cx, PWD_LEN
        jbe     @@Next
ENDM

;----------------------------------------------------------------------------------------
; Описание: (DrawFrame) заполняет буфер символами рамки
; Входные параметры: es = ds
; Возвращаемое значение: --//--
; Ожидаемое состояние: CF = 0
; Испорченные регистры: ax, cx, di
;----------------------------------------------------------------------------------------
DrawFrame       MACRO
                LOCAL   @@Next, @@TOP1, @@DOWN1, @@CNT1
                LOCAL   @@TOP2, @@DOWN2, @@CNT2, @@SubNext
                LOCAL   @@TOP3, @@DOWN3, @@CNT3
		mov     di, offset DrawBuf
		mov     al, ds: byte ptr [BACKGROUND_SYM]
		mov     ah, ds: byte ptr [FRAME_CLR]
                mov     cx, STR_LEN
		add     cx, 8
                rep     stosw

		xor     bx, bx
    	@@Next:         inc     bx
			mov     cx, 2
			rep     stosw

			cmp     bx, 1
			je      @@TOP1

				cmp     bx, STR_NUM+2
				je      @@DOWN1

                        mov     al, ds: byte ptr [FRAME_L]
			jmp     @@CNT1

		@@DOWN1:        mov     al, ds: byte ptr [L_D_CORNER]
				jmp     @@CNT1

		@@TOP1: mov     al, ds: byte ptr [L_U_CORNER]

		@@CNT1: mov     ah, ds: byte ptr [FRAME_CLR]
			mov     es: word ptr [di], ax

			add     di, 2

			cmp     bx, 1
			je      @@TOP2

				cmp     bx, STR_NUM+2
				je      @@DOWN2

					mov     al, ds: byte ptr [BACKGROUND_SYM]
					jmp     @@CNT2

	        @@DOWN2:mov     al, ds: byte ptr [FRAME_D]
			jmp     @@CNT2

	        @@TOP2: mov     al, ds: byte ptr [FRAME_T]
			jmp     @@CNT2

	     @@SubNext: jmp     @@Next

		@@CNT2: mov     cx, STR_LEN
			add     cx, 2
			rep     stosw

			cmp     bx, 1
			je      @@TOP3

				cmp     bx,  STR_NUM+2
				je      @@DOWN3

					mov     al, ds: byte ptr [FRAME_R]
					jmp     @@CNT3

	        @@DOWN3:mov     al, ds: byte ptr [R_D_CORNER]
			jmp     @@CNT3

	        @@TOP3: mov     al, ds: byte ptr [R_U_CORNER]

		@@CNT3: mov     es: word ptr [di], ax

			add     di, 2
			mov     al, ds: byte ptr [BACKGROUND_SYM]
			mov     cx, 2
			rep     stosw

		cmp     bx, STR_NUM+2
		jb      @@SubNext

		mov     al, ds: byte ptr [BACKGROUND_SYM]
		mov     cx, STR_LEN
		add     cx, 8
		rep     stosw
ENDM

;-----------------------------------------------------------------------------------------
; Описание: по центру экрана выводит строчку с соответствующим фоном
; Входные параметры: es = ds
; Возвращаемое значение: --//--
; Ожидаемое состояние: CF = 0
; Испорченные регистры: ax bx cx dx bp di si
;-----------------------------------------------------------------------------------------
WriteStr        MACRO
                mov     di, offset DrawBuf
                add     di, 2*((4+STR_LEN+4)*2+4)       ; устанавливаем смещение для первого символа строки

                mov     ah, ds: byte ptr [STRING_CLR]
                xor     cx, cx

                @@Next: mov     al, ds: byte ptr [si]
                        mov     ds: word ptr [di], ax
                        add     di, 2d
                        inc     si
                        inc     cx
                cmp     cx, STR_LEN
                jb     @@Next
ENDM

;---------------------------------------------------------------------------------------
; DropBuf: помещает буфер в текстовую видеопамять в виде прямоугольника
; Входные параметры: buf name
; Ожидаемое состояние: cs - сегмент с кодом программы Resident.asm
; Возвращаемое значение: --//--
; Испорченные регистры: ax, cx, dx, si, di, es
;---------------------------------------------------------------------------------------
DropBuf MACRO buf_name
        LOCAL @@NextL, @@NextS
        mov     si, 0b800h
        mov     es, si

        mov     si, offset buf_name

        mov     di, STR_LEN
	and     di, 0fffeh
	neg     di
	add     di, 72d
	mov     ax, STR_NUM
	inc     ax
	shr     ax, 1
	neg     ax
	add     ax, 10d
	mov     bl, 160d
	mul     bl
	add     di, ax              ; 72-(dx//2)*2+160d*(10d-((si+1)//2)

        xor     cx, cx              ; line counter
        xor     dx, dx              ; symbol in string counter

@@NextL:        inc     cx

        @@NextS:        inc     dx
                        mov     ax, cs: word ptr [si]
                        mov     es: word ptr [di], ax
                        add     di, 2
                        add     si, 2
                cmp     dx, 4+STR_LEN+4
                jb      @@NextS

                xor     dx, dx
                add     di, 160-2*(4+STR_LEN+4)
        cmp     cx, STR_NUM+4
        jb      @@NextL
ENDM

.code

org 100h

Start:  call    GetUsrPwd
        jnc     @@NErr

                mov     ax, 04ch
                int     21h
@@NErr:
        mov     si, dx

        HashFunc

        mov     ax, ds: word ptr [HASH]
        xor     ax, bx          ; вместо cmp, чтобы было менее заметно, в каком месте у меня происходит сравнение хешей
        jz      @@Granted

        mov     ds: byte ptr [FRAME_CLR],  04eh
        mov     ds: byte ptr [STRING_CLR], 040h
        mov     si, offset STR_DENIED

        jmp     @@EOP

      @@Granted:mov     ds: byte ptr [FRAME_CLR],  026h
                mov     ds: byte ptr [STRING_CLR], 020h
                mov     si, offset STR_GRANTED

@@EOP:  DrawFrame
        WriteStr
        DropBuf DrawBuf

        mov     ax, 04ch
        int     21h

;---------------------------------------------------------------------------------------
; GetUsrPwd: помещает пароль пользователя в специально отведенный буфер
; Входные параметры: SI - начало строки с данными
; Ожидаемое состояние:
; Возвращаемое значение: ax
; Испорченные регистры:
;---------------------------------------------------------------------------------------
GetUsrPwd     proc
        mov     ax, ds: word ptr [018h] ;      JFT[0] - STDIN

        cmp     ax, 0ffh                ; 0FFh - ввод не перенаправлен, идет из консоли
        jne     @@File
                ; Так как здесь не закладывается уязвимость со стеком, то можем использовать стандартную функцию
                mov     ah, 03fh
                xor     bx, bx
                mov     cx, 0ffffh
                mov     dx, offset UserPwd

                int     21h

                jmp     @@EOP
        ; здесь закладываем уязвимость со стеком, поэтому надо переписать стандартную 21h, ah = 03fh, но в немного упрощенном виде
@@File: call    CpySTDIN
@@EOP:  ret
GetUsrPwd     endp

;       SFT(SystemFileTable) - глобальная таблица ядра DOS, где хранится информация
;о каждом открытом файле/устройстве во всей системе, (под устройством подразумевает-
;ся символьное устройство, представленное драйвером, по типу: консоли, принтера, сис-
;темные часы)
;       Когда программа открывает файл (или получает перенаправленный STDIN), DOS соз-
;дает запись в SFT, а в JFT процесса кладет индекс этой записи
;       Список SFT хранится во внутренней области данных DOS, получить доступ к ней
;можно с помощью int 21, AH = 052h, после вызова ES:DX указывает на массив структур - SFT,
;массив из SFT entry.
;
;       SFT выглядит следующим образом:
;0x00   - количество занятых SFT entry
;0x02   - количество свободных SFT entry
;0x04   - указатель на следующую SFT таблицу (4 байта: сегмент:смещение)
; ...   - поочередно пошли структуры SFT entry [0], SFT entry [1], ...
;
;       SFT entry по факту является структурой и содержит внутри себя следующую информацию:
;Смещение	Размер	        Описание
;0x00	        2	        Счетчик ссылок (сколько дескрипторов указывают на эту запись)
;0x02	        2	        Режим открытия (биты: 0=чтение, 1=запись и т.д.)
;0x04	        1	        Флаги: бит 7 = 1 если устройство, 0 если файл
;0x05	        1	        Атрибуты устройства (если бит 7=1) - флаги, описывающие драйвер устройства, поддерживает STDIN STDOUT и т.д.
;0x06	        4	        Указатель на драйвер устройства (сегмент:смещение)
;0x0A	        2	        Начальный кластер файла (только для файлов)
;0x0C	        4	        Размер файла в байтах
;0x10	        4	        Текущая позиция в файле (указатель чтения/записи)
;0x14	        1	        Номер диска: 0=A, 1=B, 2=C и т.д.
;0x15	        1	        Атрибуты файла (только для файлов), про то что это за файл, например: скрытый или только для чтения или еще что-нибудь
;0x16	        4	        Указатель на IFB (Information File Block) — внутренняя структура ядра DOS, которая хранит информацию о файле
;...	        ...	        и еще много чего :)
;
;       JFT(JobFileTable) - таблица активных дескрипторов процесса
;обычно находится внутри PSP на смещении 018h (если дескрипторов не очень много, в противном случае выносится в другое место)
;представляет собой массив обычно из 20-и байт, каждый байт -индекс SFT; Значения байтов варьируются в пределах:
;       0ffh - дескриптор не открыт или указывает на устройство (под устройством подразумевается символьное устройство, представленное драйвером, по типу: консоли, принтера, системные часы)
;  000h-01fh - линейный индекс, номер SFT entry
;  JFT[0]    -    STDIN
;  JFT[1]    -    STDOUT
;  JFT[2]    -    STDERR
;  JFT[3]    -    первый открытый файл, если он был открыт
;           ...
;
;       Когда мы перенаправляем ввод, и хотим считать из него данные, нас интересует именно STDIN
;тогда мы сначала смотрим что лежит в JFT[0]
;если там лежит 0ffh, то ввод не перенаправлен и идет с CON,
;       тогда
;               я вывожу предложение ввести пароль
;               считываю его с консоли в буфер
;если там лежит не 0ffh, то ввод перенаправлен из какого-то файла
;       тогда
;               int 21, AH = 052h ---> ES:BX указывает на 0x00 SFT
;               На смещении 0x04 SFT лежит адрес следующей SFT
;               переходим по связному списку из SFT до той SFT которой будет принадлежать наш индекс JFT[0]
;                       idx = JFT[0]
;                       count = es:[bx]
;
;                       while (count <= idx)
;                       {
;                               idx = idx - count
;                               cx = es:[bx+0x04] - segment
;                               dx = es:[bx+0x06] - shift
;                               es = ax
;                               bx = dx
;                               count = es:[bx]
;                       }
;               каждая запись или SFT entry имеет постоянный размер для каждой версии DOS
;               Эта программа запускается на DOS version 5.0 и sizeof(SFT entry) = 0x3fh = 63 байт
;               Тогда наш STDIN описан структурой начало которой находится по следующему адресу:
;               ptr = es:(dx + 0x08 + 0x37h * idx)
;
;               Теперь стоит нетривиальная задача по считыванию данных из файла.
;               Общая память в DOS - диск, диск состоит из кластеров, в первых кластерах лежат важные дынные про все
;               про весь диск (загрузчик, таблица размещения файлов (FAT), таблица имен фалов), начиная кластера с номером 2
;               идет область данных, каждый кластер в любом случае это набор сегментов, а сегменты состоят из 512 байт
;
;               Из SFT entry можем получить начальный кластер файла, номер диска, размер файла и смещение от начала файла, но его мы просто устанавливаем в 0, так как читаем с начала
;               Порядок следующий:
;               1) сначала узнаем номер диска
;
;       Структура boot сектора (FAT16)
;       Смещение	Размер	Описание
;       0x00	        3	JMP-инструкция (EB 3C 90)
;       0x03	        8	OEM-имя (например "MSDOS5.0")
;       0x0B	        2	Байт на сектор (обычно 512)
;       0x0D	        1	Секторов на кластер
;       0x0E	        2	Резервных секторов (обычно 1)
;       0x10	        1	Количество FAT (обычно 2)
;       0x11	        2	Максимум записей в корне (FAT12/16)
;       0x13	        2	Всего секторов (если < 65536)
;       0x16	        2	Размер FAT в секторах (FAT16)
CpySTDIN proc
        mov     al, ds: byte ptr [018h]

        cmp     al, 0ffh
        jne     @@File

                PrintStr InPrompt

                mov     ah, 03fh
                xor     bx, bx
                mov     dx, offset UserPwd

                int     21h

                ret
@@File:
        ; al - абсолютный индекс записи (SFT entry)

        mov     ah, 052h
        int     21h
        ; es:bx - указывают на адрес  SFT
        mov     cx, es: word ptr [bx]
        mov     dx, es: word ptr [bx+02h]
        mov     es, cx
        mov     bx, dx
        ; es:bx - 0x00 SFT

        mov     ah, es: byte ptr [bx]
        ; ah - количество записей (SFT entry)
@@Next: cmp     ah, al
        ja      @@Exit

                sub     al, ah
                mov     cx, es: word ptr [bx+04h]
                mov     dx, es: word ptr [bx+06h]
                mov     es, cx
                mov     bx, dx
                mov     ah, es: byte ptr [bx]

                jmp     @@Next

@@Exit: xor     cx, cx
        mov     cl, 03fh
        add     bx, ax
        add     bx, 08h
        ;es:bx  - начало SFT entry c абсолютным индексом [JFT[0]]

        ;узнаем номер диска:
        mov     dl, es: byte ptr [bx+014h]

        cmp     dl, 1
        jbe     @@NCHNG
                add dl, 07eh
        ; dl - номер диска

        ; сохраним указатель на SFT entry [Jft[0]]
        push    es
        push    bx

@@NCHNG:;теперь считаем 0 сектор это диска, то есть часть, которая содержит BiosParameterBlock (BPB) и код загрузчика
        mov     ah, 02h
        mov     al, 1h  ; сколько считать
        mov     ch, 0h  ; номер цилиндра
        mov     cl, 1h
        mov     dh, 0h  ; головка
        mov     bx, ds
        mov     es, bx
        mov     bx, offset BootBuf

        int     13h
        jnc      @@NErr

                PrintStr ReadBootErr
                add     sp, 4h
                ret
@@NErr:
        ; Теперь надо обработать BPB (BiosParameterBlock), чтобы получить параметры файловой системы
        mov     si, offset BootBuf

        mov     ax, [si+0Bh]            ; BytesPerSector
        mov     ds: word ptr [BytesPerSector], ax

        mov     cl, [si+0Dh]            ; SectorsPerCluster
        mov     ds: byte ptr [SectorsPerCluster], cl

        mov     dx, [si+0Eh]            ; ReservedSectors
        mov     ds: word ptr [ReservedSectors], dx

        xor     bx, bx
        mov     bl, [si+10h]                ; NumberOfFATs
        mov     ds: byte ptr [NumberOfFATs], bl

        mov     ax, [si+16h]            ; FatSize
        mov     ds: word ptr [FatSize], ax

        ; Вычислить RootDirSectors
        mov     ax, [si+11h]            ; RootEntries
        mov     cx, 32
        mul     cx                      ; ax = RootEntries * 32
        dec     ax
        add     ax, ds: word ptr [BytesPerSector]
        dec     ax
        xor     dx, dx
        div     ds: word ptr [BytesPerSector]          ; ax = RootDirSectors

        ; Вычислить DataStart
        mov     cx, ax                  ; cx = RootDirSectors

        mov     ax, ds: word ptr [FatSize]
        mul     bx                      ; ax = FatSize * NumberOfFATs
        add     ax, ds: word ptr [ReservedSectors]
        add     ax, cx                  ; ax = DataStart
        mov     ds: word ptr [DataStart], ax

        ; восстанавливаем указатель на SFT entry [Jft[0]]
        pop     bx
        pop     es

        ; Вычисляем размер кластера в байтах
        xor     ax, ax
        mov     al, ds: byte ptr [SectorsPerCluster]
        mul     ds: word ptr [BytesPerSector]

        mov     ds: word ptr [ClusterSize], ax

; ========== НАЧАЛО ЧТЕНИЯ ДАННЫХ ==========

        ; 1. Взять начальный кластер из SFT entry
        mov     ax, es:[bx+0Ah]          ; ax = start_cluster
        mov     ds: word ptr [StartCluster], ax

        ; 2. Взять текущую позицию из SFT entry (4 байта)
        mov     ax, es:[bx+10h]          ; младшие 2 байта текущей позиции
        mov     dx, es:[bx+12h]          ; старшие 2 байта текущей позиции
        mov     ds: word ptr [CurrentPos], ax
        mov     ds: word ptr [CurrentPos+2], dx

        ; 3. Вычислить cluster_index и offset_in_cluster
        mov     cx, ds: word ptr [ClusterSize]
        div     cx                       ; ax = cluster_index, dx = offset_in_cluster
        mov     ds: word ptr [ClusterIndex], ax
        mov     ds: word ptr [OffsetInCluster], dx

        ; 4. Пройти по цепочке кластеров до нужного
        mov     ax, ds: word ptr [StartCluster]
        mov     cx, ds: word ptr [ClusterIndex]
        call    WalkClusterChain         ; ax = нужный кластер

        ; Проверить, что кластер не 0FFFFh (конец файла)
        cmp     ax, 0FFFFh
        je      @@EndOfFile

        ; 5. Преобразовать кластер в сектор
        ; sector = DataStart + (cluster - 2) * SectorsPerCluster + (offset_in_cluster / BytesPerSector)
        sub     ax, 2                    ; ax = cluster - 2
        xor     cx, cx
        mov     cl, SectorsPerCluster
        mul     cx                       ; ax = (cluster-2) * SectorsPerCluster
        add     ax, ds: word ptr [DataStart]  ; ax = начало кластера в секторах

        ; Добавить смещение внутри кластера
        mov     cx, ds: word ptr [OffsetInCluster]
        mov     bx, ds: word ptr [BytesPerSector]
        mov     dx, cx
        xor     dx, dx
        div     bx                       ; ax = сектор внутри кластера, dx = смещение внутри сектора
        mov     ds: word ptr [SectorNumber], ax ; ax = абсолютный сектор
        mov     ds: word ptr [SectorOffset], dx

        ; 6. Прочитать сектор
        mov     ax, ds: word ptr [SectorNumber]
        call    ReadOneSector
        jc      @@ReadError

        ; 7. Скопировать данные из буфера в UserBuf
        mov     si, offset FatSectorBuf
        add     si, ds: word ptr [SectorOffset]
        mov     di, offset UserPwd
        mov     cx, ds: word ptr [BytesPerSector]
        sub     cx, ds: word ptr [SectorOffset]  ; сколько байт до конца сектора
        rep     movsb

        ; 8. Обновить текущую позицию в SFT entry
        mov     ax, ds: word ptr [CurrentPos]
        mov     dx, ds: word ptr [CurrentPos+2]
        add     ax, cx                   ; прибавить прочитанные байты
        adc     dx, 0
        mov     es:[bx+10h], ax
        mov     es:[bx+12h], dx

        ret

@@EndOfFile:
        ; Конец файла
        mov     ax, 0
        ret

@@ReadError:
        PrintStr ReadErr
        ret

CpySTDIN endp

; ========== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==========

; Функция WalkClusterChain - проходит по цепочке кластеров
; Вход: ax = начальный кластер, cx = cluster_index (сколько кластеров пропустить)
; Выход: ax = номер нужного кластера, 0FFFFh если ошибка
WalkClusterChain proc near
        push    cx
        push    dx
        push    si

        ; Если cluster_index = 0, возвращаем начальный кластер
        cmp     cx, 0
        je      walk_done

        mov     si, cx               ; si = счетчик
        mov     cx, ax               ; cx = текущий кластер

walk_loop:
        mov     ax, cx
        call    GetNextCluster       ; ax = следующий кластер
        cmp     ax, 0FFFFh
        je      walk_error
        mov     cx, ax               ; переходим к следующему
        dec     si
        jnz     walk_loop

        mov     ax, cx               ; ax = нужный кластер
        jmp     walk_done

walk_error:
        mov     ax, 0FFFFh

walk_done:
        pop     si
        pop     dx
        pop     cx
        ret
WalkClusterChain endp

; Функция GetNextCluster - читает FAT и возвращает следующий кластер
; Вход: ax = текущий кластер
; Выход: ax = следующий кластер, 0FFFFh если конец файла или ошибка
GetNextCluster proc near
        push    bx
        push    cx
        push    dx
        push    si

        ; Для FAT16: смещение в FAT = текущий_кластер * 2
        mov     cx, ax               ; cx = cluster
        shl     ax, 1                ; ax = cluster * 2

        ; Вычислить сектор FAT, содержащий этот элемент
        xor     dx, dx
        div     ds: word ptr [BytesPerSector]  ; ax = сектор в FAT, dx = смещение внутри сектора
        mov     si, dx               ; si = offset in sector

        ; Прибавить ReservedSectors = начало FAT
        add     ax, ds: word ptr [ReservedSectors]  ; ax = абсолютный номер сектора FAT

        ; Прочитать этот сектор
        call    ReadOneSector
        jc      getnext_error

        ; Взять 2 байта из буфера по смещению si
        mov     bx, offset FatSectorBuf
        add     bx, si
        mov     ax, [bx]             ; ax = значение FAT[cluster]

        ; Проверить конец файла (для FAT16: 0xFFF8-0xFFFF)
        cmp     ax, 0FFF8h
        jb      getnext_ok
        mov     ax, 0FFFFh           ; маркер конца

getnext_ok:
        pop     si
        pop     dx
        pop     cx
        pop     bx
        ret

getnext_error:
        mov     ax, 0FFFFh
        jmp     getnext_ok
GetNextCluster endp

; Функция ReadOneSector - читает один сектор через INT 13h
; Вход: ax = номер сектора (LBA), dl = номер диска (BIOS)
; Выход: FatSectorBuf заполнен, CF=0 если успех
ReadOneSector proc near
        push    ax
        push    bx
        push    cx
        push    dx

        ; Преобразовать LBA в CHS (упрощенно для дисков < 8MB)
        ; Используем параметры: секторов на дорожку = 36 (для 1.44MB)
        ; головок = 2 (для дискет), для жестких дисков нужно получать из BIOS
        mov     bx, ax               ; сохранить LBA
        mov     ax, bx
        xor     dx, dx
        mov     cx, 36               ; SectorsPerTrack
        div     cx                   ; ax = цилиндр, dx = сектор-1
        inc     dx                   ; dx = сектор (1-based)
        mov     cl, dl               ; cl = сектор
        mov     ch, al               ; ch = цилиндр (младшие 8 бит)
        mov     ax, bx
        xor     dx, dx
        mov     cx, 36               ; SectorsPerTrack
        div     cx                   ; ax = цилиндр, dx = сектор-1
        mov     dh, al               ; dh = головка (упрощенно)

        mov     ax, 0201h            ; AH=02h (чтение), AL=1 (1 сектор)
        mov     bx, offset FatSectorBuf
        push    ds
        pop     es
        int     13h

        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ReadOneSector endp

.data
;~~~~~~~~~~~~~~~~~~~~~~~~~~~
BytesPerSector    dw ?
SectorsPerCluster db ?
ReservedSectors   dw ?
NumberOfFATs      db ?
FatSize           dw ?
DataStart         dw ?
ClusterSize       dw ?

StartCluster      dw ?
CurrentPos        dd ?
ClusterIndex      dw ?
OffsetInCluster   dw ?
SectorNumber      dw ?
SectorOffset      dw ?

;~~~~~~~~OP_STRINGS~~~~~~~~~
InPrompt        db NL
                db 'Enter the password:', EOS

STR_GRANTED     db 'Access granted'
STR_DENIED      db 'Access  denied'

STR_LEN         equ $ - STR_DENIED

ReadBootErr       db 'Read Boot Sector Err', NL, EOS
ReadErr           db 'Read Sector Error', NL, EOS

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
FRAME_CLR       db 0
STRING_CLR      db 0

;~~~~~~~~~Buffers~~~~~~~~~~~
BootBuf         db 512 dup(?)

FatSectorBuf    db 512 dup(0)

DrawBuf         dw (4+STR_NUM)*(8+STR_LEN) dup(?) ; заполняем вопросами чтобы небыло понятно, что это относится к данным

UserPwd         db 256 dup(?)

PWD_LEN         dw 256

HASH            dw 01433h ; use PwdHashGenerator.asm

;~~~~~~~~~Rubbish~~~~~~~~~~~
Rubbish         db 273 dup(?)
Rubbish1        db 127
Rubbish2        dw 0C560h


End Start
