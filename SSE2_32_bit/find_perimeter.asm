segment .text
    global find_perimeter
    extern printf

find_perimeter:
    push ebx
    
    sub esp, 16

    ; [esp] ~ [esp + 15]: local variables
    ; [esp] ~ [esp + 15]:  memory to work with XMMs (packed to scalar)
    ;
    ; [esp + 16]:  previous ebx
    ;
    ; [esp + 20]:  return address
    ;
    ; [esp + 24]:  x coordinates array (input) - 32_bit floating point array
    ; [esp + 28]:  y coordinates array (input) - 32_bit floating point array
    ; [esp + 32]:  number of points    (input) - 32_bit signed int
    ;
    ; ebx:         main loop iterator (array index)
    ; eax:         number of points (changes during code)
    ; ecx:         x coordiantes array
    ; edx:         y coordinates array
    ;
    ; st0:        perimeter
    ;
    ; xmm0:        sum of first 4 * k edge lengths (each part sum of 1/4 of edges)

    mov eax, dword [esp + 32]
    mov ebx, 1
    mov ecx, dword [esp + 24]
    mov edx, dword [esp + 28]

    movups xmm0, xmm0 ; setting xmm0 to zeros {0, 0, 0, 0}
    fldz

    sub eax, 4 ; eax = n - 4
    jle end_of_four_iteration_loop
    four_iteration_loop: ; iterating over array doing calculations 4 by 4
        movups xmm1, [ecx + 4 * ebx]     ; xmm1 = {x[i], x[i + 1], x[i + 2], x[i + 3]}
        subps xmm1, [ecx + 4 * ebx - 4]  ; xmm1 = {d_x1, d_x2, d_x3, d_x4} = {x[i] - x[i - 1], x[i + 1] - x[i], x[i + 2] - x[i + 1], x[i + 3] - x[i + 2]}
        mulps xmm1, xmm1                 ; xmm1 = {d_x1 ^ 2, d_x2 ^ 2, d_x3 ^ 2, d_x4 ^ 2}

        movups xmm2, [edx + 4 * ebx]     ; xmm2 = {y[i], y[i + 1], y[i + 2], y[i + 3]} 
        subps xmm2, [edx + 4 * ebx - 4]  ; xmm2 = {d_y1, d_y2, d_y3, d_y4} = {y[i] - y[i - 1], y[i + 1] - y[i], y[i + 2] - y[i + 1], y[i + 3] - y[i + 2]}
        mulps xmm2, xmm2                 ; xmm2 = {d_y1 ^ 2, d_y2 ^ 2, d_y3 ^ 2, d_y4 ^ 2}

        addps xmm1, xmm2                 ; xmm1 = {l1 ^ 2, l2 ^ 2, l3 ^ 2, l4 ^ 2}
        sqrtps xmm1, xmm1                ; xmm1 = {l1, l2, l3, l4}
        
        addps xmm0, xmm1                 ; sum += {l1, l2, l3, l4}

        add ebx, 4 ; i += 4
        cmp ebx, eax
        jl four_iteration_loop

    ; Adding all edges lengths to st0 (perimeter)
    movups [esp], xmm0
    fld dword [esp]
    fld dword [esp + 4]
    faddp st1
    fld dword [esp + 8]
    faddp st1
    fld dword [esp + 12]
    faddp st1

    end_of_four_iteration_loop:

    add eax, 4 ; eax = n
    cmp ebx, eax
    jge end_of_one_iteration_loop
    one_iteration_loop: ; iterating over remaining elements 1 by 1
        fld dword [ecx + 4 * ebx]     ; loading x1 = x[i]
        fld dword [ecx + 4 * ebx - 4] ; loading x2 = x[i - 1]
        fsubp st1                     ; calculating d_x = (x1 - x2)
        fmul st0                      ; calculating d_x ^ 2
        fld dword [edx + 4 * ebx]     ; loading y1 = y[i]
        fld dword [edx + 4 * ebx - 4] ; loading y2 = y[i - 1]
        fsubp st1                     ; calculating d_y = (y1 - y2)
        fmul st0                      ; calculating d_y ^ 2
        faddp st1                     ; calculating length ^ 2
        fsqrt                         ; calculating length
        
        faddp st1 ; perimeter += edge_length

        inc ebx
        cmp ebx, eax
        jl one_iteration_loop        

    end_of_one_iteration_loop:

    ; Calculations for last edge
    fld dword [ecx]               ; loading x1 = x[0]
    fld dword [ecx + 4 * eax - 4] ; loading x2 = x[n - 1]
    fsubp st1                     ; calculating d_x = (x1 - x2)
    fmul st0                      ; calculating d_x ^ 2
    fld dword [edx]               ; loading y1 = y[0]
    fld dword [edx + 4 * eax - 4] ; loading y2 = y[n - 1]
    fsubp st1                     ; calculating d_y = (y1 - y2)
    fmul st0                      ; calculating d_y ^ 2
    faddp st1                     ; calculating length ^ 2
    fsqrt                         ; calculating length

    faddp st1 ; perimeter += edge length

    ;output is already in st0
    add esp, 16 ; clearing local variables from stack

    pop ebx

    ret
