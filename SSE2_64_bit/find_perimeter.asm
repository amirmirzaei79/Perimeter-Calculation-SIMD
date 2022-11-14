segment .text
    global find_perimeter
    extern printf

find_perimeter:   
    sub rsp, 16

    ; [rsp] ~ [rsp + 15]: local variables
    ; [rsp] ~ [rsp + 15]:  memory to work with XMMs (packed to scalar)
    ;
    ; [rsp + 16]:  return address
    ;
    ; rdi:         x coordinates array (input) - 32_bit floating point array
    ; rsi:         y coordinates array (input) - 32_bit floating point array
    ; rdx:         number of points    (input) - 32_bit signed int           (changes during code)
    ;
    ; rax:         main loop iterator (array index)
    ;
    ; xmm0:       perimeter
    ; xmm1:       sum of first 4 * k edge lengths (each part sum of 1/4 of edges) - changes after SIMD section (four_iteration_loop)
    
    mov rax, 1

    xorps xmm1, xmm1 ; setting xmm1 to zeros {0, 0, 0, 0}
    movss xmm0, xmm1 ; setting xmm0 (perimeter) to zero (scalar)

    sub rdx, 4 ; rdx = n - 4
    jle end_of_four_iteration_loop
    four_iteration_loop: ; iterating over array doing calculations 4 by 4
        movups xmm2, [rdi + 4 * rax]     ; xmm2 = {x[i], x[i + 1], x[i + 2], x[i + 3]}
        subps xmm2, [rdi + 4 * rax - 4]  ; xmm2 = {d_x1, d_x2, d_x3, d_x4} = {x[i] - x[i - 1], x[i + 1] - x[i], x[i + 2] - x[i + 1], x[i + 3] - x[i + 2]}
        mulps xmm2, xmm2                 ; xmm2 = {d_x1 ^ 2, d_x2 ^ 2, d_x3 ^ 2, d_x4 ^ 2}

        movups xmm3, [rsi + 4 * rax]     ; xmm3 = {y[i], y[i + 1], y[i + 2], y[i + 3]} 
        subps xmm3, [rsi + 4 * rax - 4]  ; xmm3 = {d_y1, d_y2, d_y3, d_y4} = {y[i] - y[i - 1], y[i + 1] - y[i], y[i + 2] - y[i + 1], y[i + 3] - y[i + 2]}
        mulps xmm3, xmm3                 ; xmm3 = {d_y1 ^ 2, d_y2 ^ 2, d_y3 ^ 2, d_y4 ^ 2}

        addps xmm2, xmm3                 ; xmm2 = {l1 ^ 2, 5l2 ^ 2, l3 ^ 2, l4 ^ 2}
        sqrtps xmm2, xmm2                ; xmm2 = {l1, l2, l3, l4}
        
        addps xmm1, xmm2                 ; sum += {l1, l2, l3, l4}

        add rax, 4 ; i += 4
        cmp rax, rdx
        jl four_iteration_loop

    ; Adding all edges lengths to xmm0 (perimeter)
    movups [rsp], xmm1
    movss xmm0, [rsp]
    addss xmm0, [rsp + 4]
    addss xmm0, [rsp + 8]
    addss xmm0, [rsp + 12]

    end_of_four_iteration_loop:

    add rdx, 4 ; rdx = n
    cmp rax, rdx
    jge end_of_one_iteration_loop
    one_iteration_loop: ; iterating over remaining elements 1 by 1
        movss xmm1, [rdi + 4 * rax]      ; xmm1 = x[i]
        subss xmm1, [rdi + 4 * rax - 4]  ; xmm1 = d_x = x[i] - x[i - 1]
        mulss xmm1, xmm1                 ; xmm1 = d_x ^ 2
        movss xmm2, [rsi + 4 * rax]      ; xmm2 = y[i]
        subss xmm2, [rsi + 4 * rax - 4]  ; xmm2 = d_y = y[i] - y[i - 1]
        mulss xmm2, xmm2                 ; xmm2 = d_y ^ 2   
        addss xmm1, xmm2                 ; xmm1 = length ^ 2
        sqrtss xmm1, xmm1                ; xmm1 = length

        addss xmm0, xmm1                 ; xmm0 (perimeter) += length

        inc rax
        cmp rax, rdx
        jl one_iteration_loop        

    end_of_one_iteration_loop:

    ; Calculations for last edge
    movss xmm1, [rdi]                ; xmm1 = x[0]
    subss xmm1, [rdi + 4 * rdx - 4]  ; xmm1 = d_x = x[0] - x[n - 1]
    mulss xmm1, xmm1                 ; xmm1 = d_x ^ 2
    movss xmm2, [rsi]                ; xmm2 = y[0]
    subss xmm2, [rsi + 4 * rdx - 4]  ; xmm2 = d_y = y[0] - y[n - 1]
    mulss xmm2, xmm2                 ; xmm2 = d_y ^ 2   
    addss xmm1, xmm2                 ; xmm1 = length ^ 2
    sqrtss xmm1, xmm1                ; xmm1 = length

    addss xmm0, xmm1                ; xmm0 (perimeter) += length
    
    add rsp, 16 ; clearing local variables from stack

    ret
