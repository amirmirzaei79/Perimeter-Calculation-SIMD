segment .text
    global find_perimeter
    extern printf

find_perimeter:
    push ebx
    push esi
    push edi
    push ebp
    
    sub esp, 33

    mov byte [esp],      '%'
    mov byte [esp + 1],  'l'
    mov byte [esp + 2],  'f'
    mov byte [esp + 3],  10
    mov byte [esp + 4],  '%'
    mov byte [esp + 5],  'l'
    mov byte [esp + 6],  'f'
    mov byte [esp + 7],  10
    mov byte [esp + 8],  '%'
    mov byte [esp + 9],  'l'
    mov byte [esp + 10], 'f'
    mov byte [esp + 11], 10
    mov byte [esp + 12], '%'
    mov byte [esp + 13], 'l'
    mov byte [esp + 14], 'f'
    mov byte [esp + 15], 10
    mov byte [esp + 16], 0

    ; [esp] ~ [esp + 32]: local variables
    ; [esp] ~ [esp + 16]:       printf format
    ; [esp + 17] ~ [esp + 32]:  memory to work with XMMs (packed to scalar)
    ;
    ; [esp + 33]:  previous ebp
    ; [esp + 37]:  previous edi
    ; [esp + 41]:  previous esi
    ; [esp + 45]:  previous ebx
    ;
    ; [esp + 49]:  return address
    ;
    ; [esp + 53]:  x coordinates array (input) - 32_bit floating point array
    ; [esp + 57]:  y coordinates array (input) - 32_bit floating point array
    ; [esp + 61]:  number of points    (input) - 32_bit signed int
    ;
    ; ebx:         main loop iterator (array index)
    ; ebp:         number of points (changes during code)
    ; esi:         x coordiantes array
    ; edi:         y coordinates array
    ;
    ; st0:        perimeter
    ;
    ; xmm0:        sum of first 4 * k edge lengths (each part sum of 1/4 of edges)

    mov ebp, dword [esp + 61]
    mov ebx, 1
    mov esi, dword [esp + 53]
    mov edi, dword [esp + 57]

    xorps xmm0, xmm0 ; setting xmm0 to zeros {0, 0, 0, 0}
    fldz 

    sub ebp, 4 ; ebp = n - 4
    jle end_of_four_iteration_loop
    four_iteration_loop: ; iterating over array doing calculations 4 by 4
        movups xmm1, [esi + 4 * ebx]     ; xmm1 = {x[i], x[i + 1], x[i + 2], x[i + 3]}
        subps xmm1, [esi + 4 * ebx - 4]  ; xmm1 = {d_x1, d_x2, d_x3, d_x4} = {x[i] - x[i - 1], x[i + 1] - x[i], x[i + 2] - x[i + 1], x[i + 3] - x[i + 2]}
        mulps xmm1, xmm1                 ; xmm1 = {d_x1 ^ 2, d_x2 ^ 2, d_x3 ^ 2, d_x4 ^ 2}

        movups xmm2, [edi + 4 * ebx]     ; xmm2 = {y[i], y[i + 1], y[i + 2], y[i + 3]} 
        subps xmm2, [edi + 4 * ebx - 4]  ; xmm2 = {d_y1, d_y2, d_y3, d_y4} = {y[i] - y[i - 1], y[i + 1] - y[i], y[i + 2] - y[i + 1], y[i + 3] - y[i + 2]}
        mulps xmm2, xmm2                 ; xmm2 = {d_y1 ^ 2, d_y2 ^ 2, d_y3 ^ 2, d_y4 ^ 2}

        addps xmm1, xmm2                 ; xmm1 = {l1 ^ 2, l2 ^ 2, l3 ^ 2, l4 ^ 2}
        sqrtps xmm1, xmm1                ; xmm1 = {l1, l2, l3, l4}
        
        addps xmm0, xmm1                 ; sum += {l1, l2, l3, l4}

        ; printing edges lengths using printf
        cvtps2pd xmm2, xmm1
        movhlps xmm3, xmm1
        cvtps2pd xmm3, xmm3
        movupd [esp - 32], xmm2
        movupd [esp - 16], xmm3
        mov [esp - 36], esp
        sub esp, 36
        call printf
        add esp, 36

        add ebx, 4 ; i += 4
        cmp ebx, ebp
        jl four_iteration_loop

    ; Adding all edges lengths to st0 (perimeter)
    movups [esp + 17], xmm0
    fld dword [esp + 17]
    fld dword [esp + 21]
    faddp st1
    fld dword [esp + 25]
    faddp st1
    fld dword [esp + 29]
    faddp st1

    end_of_four_iteration_loop:

    mov byte [esp + 4], 0 ; changing printf format to print only one number

    add ebp, 4 ; ebp = n
    cmp ebx, ebp
    jge end_of_one_iteration_loop
    one_iteration_loop: ; iterating over remaining elements 1 by 1
        fld dword [esi + 4 * ebx]     ; loading x1 = x[i]
        fld dword [esi + 4 * ebx - 4] ; loading x2 = x[i - 1]
        fsubp st1                     ; calculating d_x = (x1 - x2)
        fmul st0                      ; calculating d_x ^ 2
        fld dword [edi + 4 * ebx]     ; loading y1 = y[i]
        fld dword [edi + 4 * ebx - 4] ; loading y2 = y[i - 1]
        fsubp st1                     ; calculating d_y = (y1 - y2)
        fmul st0                      ; calculating d_y ^ 2
        faddp st1                     ; calculating length ^ 2
        fsqrt                         ; calculating length
        
        ; printing edge length using printf function
        fst qword [esp - 8]
        mov dword [esp - 12], esp
        sub esp, 12
        call printf
        add esp, 12
        
        faddp st1 ; perimeter += edge_length

        inc ebx
        cmp ebx, ebp
        jl one_iteration_loop        

    end_of_one_iteration_loop:

    ; Calculations for last edge
    fld dword [esi]               ; loading x1 = x[0]
    fld dword [esi + 4 * ebp - 4] ; loading x2 = x[n - 1]
    fsubp st1                     ; calculating d_x = (x1 - x2)
    fmul st0                      ; calculating d_x ^ 2
    fld dword [edi]               ; loading y1 = y[0]
    fld dword [edi + 4 * ebp - 4] ; loading y2 = y[n - 1]
    fsubp st1                     ; calculating d_y = (y1 - y2)
    fmul st0                      ; calculating d_y ^ 2
    faddp st1                     ; calculating length ^ 2
    fsqrt                         ; calculating length

    ; printing edge length using printf function
    fst qword [esp - 8]
    mov dword [esp - 12], esp
    sub esp, 12
    call printf
    add esp, 12

    faddp st1 ; perimeter += edge length

    ;output is already in st0
    add esp, 33 ; clearing local variables from stack
    pop ebp
    pop edi
    pop esi
    pop ebx

    ret
