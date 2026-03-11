.model tiny
.code
.286

org 100h

Start:
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

        mov     es: word ptr [06666h],      060E4h        ; in  al, 60h
        mov     es: word ptr [06666h+2h],   0013Ch        ; cmp al, 01h
        mov     es: word ptr [06666h+4h],   0F875h        ; jne -8d         (jne 07777h:06666h)
        mov     es: byte ptr [06666h+6h],   0CBh          ; retf

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

;AGAIN: in  al, 60h
;       cmp al, 1   ; ScanCode(Esc)
;       jne AGAIN
;
;       retf

I_Ptr:  mov     ah, 04ch
        int     21h

End Start
