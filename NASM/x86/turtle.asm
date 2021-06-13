section .text
global turtle
turtle:
        push    ebp
        mov     ebp, esp
        ; Some of the register cannot be changed after the execution of the method. Here they are:
        push    ebx
        push    edi
        push    esi
        ; Initial return code
        mov     eax, 0
        mov     esi, DWORD [ebp+16] ; Address of the context
        mov     bl, BYTE [esi+13]   ; Get the set position tag from local index.
        cmp     bl, 0
        jz      not_set_position
        mov     BYTE [esi+13], 0    ; Resets the set position tag.
        jmp     set_position_logic

not_set_position:
        ;  load command
        mov     ecx, DWORD [ebp+12] ; address of *command to ECX
        xor     ebx, ebx            ; ebx clear
        mov     bx, WORD [ecx]      ; load command into BX
        rol     bx, 8               ; byte swap

        ; We are retriving first two bits.
        mov     edx, ebx
        and     edx, 0xC000         ; 1100 0000 0000 0000

        ; Running the instructions
        cmp     edx, 0x8000         ; 1000 0000 0000 0000 (set pen state)
        jz      set_pen_state
        cmp     edx, 0xC000         ; 1100 0000 0000 0000 (move)
        jz      move_command
        cmp     edx, 0x00           ; 0000 0000 0000 0000 (set pen state)
        jz      set_direction
        cmp     edx, 0x4000         ; 0100 0000 0000 0000 (set position)
        jz      set_position
        jmp     finish
;------------------------------Setting the pen state----------------
set_pen_state:
        mov     dl, bl
        shl     dl, 4
        and     dl, 0xF0
        mov     [esi+10], dl    ;setting the red color
        and     bl, 0xF0
        mov     [esi+9], bl     ;setting the green color
        shr     bx, 4
        and     bl, 0xF0
        mov     [esi+8], bl     ;setting the blue color
        shr     bx, 4           ;shifting 8 bits to get
        shr     bx, 4
        and     bl, 1
        mov     [esi+11], bl   
        jmp     finish
;-------------------------------------------------------------------
move_command:
        mov     ecx, ebx        ; distance
        and     ecx, 0x3FF
        
        ; Logic switches (direction of a movement)
        mov     dl, BYTE [esi+12]   ;direction from the input
        cmp     dl, 1           ; left direction
        jz      move_left
        cmp     dl, 0           ; up direction
        jz      move_up
        cmp     dl, 2           ; down direction
        jz      move_down
                                ; right direction

        ; Distance verification
        mov     edi, DWORD [ebp+8]      ; Address of the image to EDI
        mov     edx, DWORD [edi+18]     ; Width from header file.
        dec     edx                     ; width - 1
        sub     edx, DWORD [esi]        ; Header width - current width.
        cmp     ecx, edx                ;
        jbe     move_right              ; LE = less or equal
        mov     ecx, edx
        or      eax, 10                 ; ERROR: return code 10 (incorect command)
move_right:
        ; Checking the pen
        mov     dl, BYTE [esi+11]   ; Adress of the pen state.
        cmp     dl, 0   
        jz      paint_right
        ; When pen is up we need to finish the execution.
        add     [esi], ecx      ; Updating the new X
        jmp     finish

paint_right:
        ; pixel address determination
        mov     ebx, DWORD [edi+18]
        lea     ebx, [ebx + 2 * ebx + 3]
        and     ebx, 0xFFFFFFFC     ; 1111 1111 1111 1111 1111 1111 1111 1100
        push    eax
        mov     eax, DWORD [esi+4]
        mul     ebx
        add     edi, 54             ; Header size
        add     edi, eax
        pop     eax
        mov     edx, DWORD [esi]
        lea     edx, [edx + 2 * edx]
        add     edi, edx
        add     [esi], ecx          ; Updating the new X

        mov     esi, DWORD [esi+8]  ; Getting the colors.
        inc     ecx
paint_right_loop:
        mov     edx, esi
        mov     BYTE [edi], dl
        shr     edx, 8
        mov     BYTE [edi+1], dl
        shr     edx, 8
        mov     BYTE [edi+2], dl
        add     edi, 3
        loop    paint_right_loop
        jmp     finish
move_left:
        ; dist verification
        mov     edx, DWORD [esi]
        cmp     ecx, edx
        jbe     paint_left
        ; When pen is up we need to finish the execution.
        mov     ecx, edx
        or      eax, 10                 ; ERROR: return code 10 (incorect command)

paint_left:
        ; Checking the pen
        mov     dl, BYTE [esi+11]
        cmp     dl, 0
        jz      go_paint_left
        ; When pen is up we need to finish the execution.
        sub     [esi], ecx      ; Updating the new X
        jmp     finish

go_paint_left:
        ; pixel address determination
        mov     edi, DWORD [ebp+8]      ; Address of the image

        mov     ebx, DWORD [edi+18]
        lea     ebx, [ebx + 2 * ebx + 3]
        and     ebx, 0xFFFFFFFC         ; 1111 1111 1111 1111 1111 1111 1111 1100
        push    eax
        mov     eax, DWORD [esi+4]
        mul     ebx
        add     edi, 54                 ; Header size
        add     edi, eax
        pop     eax
        mov     edx, DWORD [esi]
        lea     edx, [edx + 2 * edx]
        add     edi, edx

        sub     [esi], ecx              ; Updating the new X
        
        mov     esi, DWORD [esi+8]      ; Getting the colors.
        inc     ecx
go_paint_left_loop:
        mov     edx, esi
        mov     BYTE [edi], dl
        shr     edx, 8
        mov     BYTE [edi+1], dl
        shr     edx, 8
        mov     BYTE [edi+2], dl
        sub     edi, 3
        loop    go_paint_left_loop
        jmp     finish
move_up:
        mov     edi, DWORD [ebp+8]      ; Getting the image
        mov     edx, DWORD [edi+22]     ; get height from BMP header
        dec     edx
        sub     edx, DWORD [esi+4]

        cmp     ecx, edx
        jbe     paint_up
        mov     ecx, edx
        or      eax, 10                 ; ERROR: return code 10 (incorect command)
paint_up:
        mov     dl, BYTE [esi+11]
        cmp     dl, 0
        jz      go_up_paint
        add     [esi+4], ecx      ; Updating the new Y
        jmp     finish
go_up_paint:
        ; pixel address determination
        mov     ebx, DWORD [edi+18]
        lea     ebx, [ebx + 2 * ebx + 3]
        and     ebx, 0xFFFFFFFC     ; 1111 1111 1111 1111 1111 1111 1111 1100
        push    eax
        mov     eax, DWORD [esi+4]
        mul     ebx
        add     edi, 54
        add     edi, eax
        pop     eax
        mov     edx, DWORD [esi]
        lea     edx, [edx + 2 * edx]
        add     edi, edx
        add     [esi+4], ecx      ; Updating the new Y
        mov     esi, DWORD [esi+8]
        inc     ecx
go_up_paint_loop:
        mov     edx, esi
        mov     BYTE [edi], dl
        shr     edx, 8
        mov     BYTE [edi+1], dl
        shr     edx, 8
        mov     BYTE [edi+2], dl
        add     edi, ebx
        loop    go_up_paint_loop
        jmp     finish
move_down:
        mov     edx, DWORD [esi+4]

        cmp     ecx, edx
        jbe     paint_down
        mov     ecx, edx
        or      eax, 10                 ; ERROR: return code 10 (incorect command)
paint_down:
        mov     dl, BYTE [esi+11]
        cmp     dl, 0
        jz      move_down_paint
        sub     [esi+4], ecx            ; Updating the new Y
        jmp     finish
move_down_paint:
        mov     edi, DWORD [ebp+8]      ; Getting the image

        mov     ebx, DWORD [edi+18]
        lea     ebx, [ebx + 2 * ebx + 3]
        and     ebx, 0xFFFFFFFC         ; 1111 1111 1111 1111 1111 1111 1111 1100
        push    eax
        mov     eax, DWORD [esi+4]
        mul     ebx
        add     edi, 54
        add     edi, eax
        pop     eax
        mov     edx, DWORD [esi]
        lea     edx, [edx + 2 * edx]
        add     edi, edx
        sub     [esi+4], ecx            ; Updating the new Y
        mov     esi, DWORD [esi+8]
        inc     ecx
move_down_paint_loop:
        mov     edx, esi
        mov     BYTE [edi], dl
        shr     edx, 8
        mov     BYTE [edi+1], dl
        shr     edx, 8
        mov     BYTE [edi+2], dl
        sub     edi, ebx
        loop    move_down_paint_loop
        jmp     finish
;----------------Sets the direction command-------------------
set_direction:
        and     bx, 3           ; 11
        mov     [esi+12], bl
        jmp     finish
;-------------------------------------------------------------
;----------------Sets the position----------------------------
set_position:
        mov     BYTE [esi+13], 1        ; Setting the set position tag in context.
        jmp     finish
set_position_logic:
        mov     ecx, DWORD [ebp+12]     ; Address of the command
        xor     ebx, ebx                ; ebx clear
        mov     bx, WORD [ecx]          ; load command into BX
        rol     bx, 8                   ; byte swap
        
        mov     edi, DWORD [ebp+8]      ; getting the bitmap
        mov     edx, DWORD [edi+18]     ; getting the width from the header
        dec     edx                     ; width - 1
        mov     ecx, ebx                ; saving 
        and     ebx, 0x3FF              ; 0000 0001 1111 1111
        cmp     ebx, edx
        ;cmp     edx, ebx
        jbe     good_x
        mov     ebx, edx                ; if x is to big we will set the value to width - 1
good_x:
        mov     DWORD [esi], ebx        ; new x position
        mov     edx, DWORD [edi+22]     ; getting the height from the header
        dec     edx
        mov     ebx, ecx                ; retrieving saved data
        shr     ebx, 10                 ; shifting the x
        and     ebx, 0x0000003F         ; 0000 0000 0011 1111
        cmp     ebx, edx
        jbe     good_y
        mov     ebx, edx
        or      eax, 1                  ; if y is to big we will set the value to height - 1
good_y:
        mov DWORD [esi+4], ebx          ; new y position
;-------------------------------------------------------------
;--------------returning and retrieving necessary register----
finish:
        pop esi
        pop edi
        pop ebx

        pop ebp
        ret