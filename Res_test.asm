.model tiny
.code
.286

org 100h

Start:
        mov     di, offset ST_CPY
        mov     si, 7777h
        mov     es, si
        mov     si, 6666h

        Next:   mov     al, cs: byte ptr [di]
                mov     es: byte ptr [si], al
                inc     di
                inc     si
        cmp     di, offset END_CPY
        jbe     Next

        mov     bx, 0BBBBh
        mov     cx, 0CCCCh
        mov     dx, 0DDDDh
        mov     si, 0EEEEh
        mov     di, 0FFFFh
        mov     bp, 01111h

        mov     ax, 02222h
        mov     ds, ax

        mov     sp, 05559h  ; = 04444 + place for return address

        mov     ax, 04444h
        mov     ss, ax

        mov     ax, 07777h
        mov     es, ax

        mov     ax, 03333h
        mov     es, ax

        push    cs

        mov     ax, offset  I_Ptr   ;\__ push ip
        push    ax                  ;/

        mov     ax, 07777h
        push    ax

        mov     ax, 06666h
        push    ax

        mov     ax, 0AAAAh
        retf

I_Ptr:  mov     ah, 04ch
        int     21h

ST_CPY: in  al, 60h
        cmp al, 1   ; ScanCode(Esc)
        jne ST_CPY

        retf
END_CPY:

End Start
