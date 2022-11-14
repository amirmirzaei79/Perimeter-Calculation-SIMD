segment .text
    global find_perimeter
    extern printf

find_perimeter:
    push ebx
    push esi
    push edi
    push ebp

    sub esp, 4

    mov byte [esp], '%'
    mov byte [esp + 1], 'f'
    mov byte [esp + 2], 10
    mov byte [esp + 3], 0

    ; [esp] ~ [esp + 3]: printf format (local variable) - ("%f" , 10 , 0)
    ;
    ; [esp + 4]:   previous ebx
    ; [esp + 8]:   previous esi
    ; [esp + 12]:  previous edi
    ; [esp + 16]:  previous ebp
    ;
    ; [esp + 20]:   return address
    ;
    ; [esp + 24]:  x coordinates array (input) - 32_bit floating point array
    ; [esp + 28]:  y coordinates array (input) - 32_bit floating point array
    ; [esp + 32]:  number of points    (input) - 32_bit signed int
    ;
    ; ebx:        main loop iterator (array index)
    ; ebp:        number of points
    ; esi:        x coordiantes array
    ; edi:        y coordinates array

    mov ebp, dword [esp + 32]
    mov ebx, 1
    mov esi, dword [esp + 24]
    mov edi, dword [esp + 28]

    fldz ; setting perimeter to zero (st0 = perimeter)

    main_loop: ; iterating over arrays (from 1 to n - 1)
        fld dword [esi + 4 * ebx]     ; loading x1 = x[i]
        fld dword [esi + 4 * ebx - 4] ; loading x2 = x[i - 1]
        fsubp st1 ; calculating (x1 - x2)
        fmul st0  ; calculating (x1 - x2) * (x1 - x2)
        fld dword [edi + 4 * ebx]     ; loading y1 = y[i]
        fld dword [edi + 4 * ebx - 4] ; loading y2 = y[i - 1]
        fsubp st1 ; calculating (y1 - y2)
        fmul st0  ; calculating (y1 - y2) * (y1 - y2)
        faddp st1 ; calculating (x1 - x2) ^ 2 + (y1 - y2) ^ 2 = edge_length ^ 2
        fsqrt ; calculating sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2) = edge_length
        
        ; printing edge_length using printf function
        ; next 3 instructions are instead of pushing for faster operations
        ;  and using less registers and fewer memory access instructions
        fst qword [esp - 8]
        mov dword [esp - 12], esp
        sub esp, 12
        call printf
        add esp, 12 ; clearing input from stack
        
        faddp st1 ; perimeter += edge_length

        inc ebx
        cmp ebx, ebp
        jl main_loop

    fld dword [esi]     ; loading x1 = x[0]
    fld dword [esi + 4 * ebp - 4] ; loading x2 = x[n - 1]
    fsubp st1 ; calculating (x1 - x2)
    fmul st0  ; calculating (x1 - x2) * (x1 - x2)
    fld dword [edi]     ; loading y1 = y[0]
    fld dword [edi + 4 * ebp - 4] ; loading y2 = y[n - 1]
    fsubp st1 ; calculating (y1 - y2)
    fmul st0  ; calculating (y1 - y2) * (y1 - y2)
    faddp st1 ; calculating (x1 - x2) ^ 2 + (y1 - y2) ^ 2 = edge_length ^ 2
    fsqrt ; calculating sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2) = edge_length
    ; printing edge_length using printf function
    ; next 3 instructions are instead of pushing for faster operations
    ;  and using less registers and fewer memory access instructions
    fst qword [esp - 8]
    mov dword [esp - 12], esp
    sub esp, 12
    call printf
    add esp, 12 ; clearing input from stack
        
    faddp st1 ; perimeter += edge_length

    ; output is already in st0
    add esp, 4 ; clearing local variables from stack
    pop ebp
    pop edi
    pop esi
    pop ebx

    ret
