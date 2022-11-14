segment .text
    global find_perimeter
    extern printf

find_perimeter:   
    ; [rsp]:  return address
    ;
    ; rdi:         x coordinates array (input) - 32_bit floating point array
    ; rsi:         y coordinates array (input) - 32_bit floating point array
    ; rdx:         number of points    (input) - 32_bit signed int           (changes during code)
    ;
    ; rax:         main loop iterator (array index)
    ;
    ; xmm0:       perimeter
    ; ymm1:       sum of first 8 * k edge lengths (each part sum of 1/8 of edges)
    ; xmm1:       next 4 edges (if they exist) lengths will be added

    mov rax, 1

    vpxor ymm1, ymm1, ymm1 ; setting ymm1 to zeros {0, 0, 0, 0, 0, 0, 0, 0}
    movss xmm0, xmm1       ; setting xmm0 (perimeter) to zero (scalar)

    sub rdx, 8 ; rdx = n - 8
    jle end_of_eight_iteration_loop
    eight_iteration_loop: ; iterating over array doing calculations 8 by 8
        vmovups ymm2, [rdi + 4 * rax]           ; ymm2 = {x[i] ~ x[i + 7]}
        vsubps ymm2, ymm2, [rdi + 4 * rax - 4]  ; ymm2 = {d_x1 ~ d_x8} = {x[i] - x[i - 1] ~ x[i + 7] - x[i + 6]}
        vmulps ymm2, ymm2, ymm2                 ; ymm2 = {d_x1 ^ 2 ~ d_x8 ^ 2}

        vmovups ymm3, [rsi + 4 * rax]           ; ymm3 = {y[i] ~ y[i + 7]}
        vsubps ymm3, ymm3, [rsi + 4 * rax - 4]  ; ymm3 = {d_y1 ~ d_y8} = {y[i] - y[i - 1] ~ y[i + 7] - y[i + 6]}
        vmulps ymm3, ymm3, ymm3                 ; ymm3 = {d_y1 ^ 2 ~ d_y8 ^ 2}

        vaddps ymm2, ymm2, ymm3                 ; ymm2 = {l1 ^ 2 ~ l8 ^ 2}
        vsqrtps ymm2, ymm2                      ; ymm2 = {l1 ~ l8}

        vaddps ymm1, ymm2                       ; sum (ymm1) += {l1 ~ l8}

        add rax, 8 ; i += 8
        cmp rax, rdx
        jl eight_iteration_loop
    end_of_eight_iteration_loop:

    add rdx, 4 ; rdx = n - 4
    cmp rax, rdx
    jg end_of_four_iteration_if
    four_iteration_if: ; SIMD calculations for 4 edges
        movups xmm2, [rdi + 4 * rax]     ; xmm2 = {x[i], x[i + 1], x[i + 2], x[i + 3]}
        subps xmm2, [rdi + 4 * rax - 4]  ; xmm2 = {d_x1, d_x2, d_x3, d_x4} = {x[i] - x[i - 1], x[i + 1] - x[i], x[i + 2] - x[i + 1], x[i + 3] - x[i + 2]}
        mulps xmm2, xmm2                 ; xmm2 = {d_x1 ^ 2, d_x2 ^ 2, d_x3 ^ 2, d_x4 ^ 2}

        movups xmm3, [rsi + 4 * rax]     ; xmm3 = {y[i], y[i + 1], y[i + 2], y[i + 3]} 
        subps xmm3, [rsi + 4 * rax - 4]  ; xmm3 = {d_y1, d_y2, d_y3, d_y4} = {y[i] - y[i - 1], y[i + 1] - y[i], y[i + 2] - y[i + 1], y[i + 3] - y[i + 2]}
        mulps xmm3, xmm3                 ; xmm3 = {d_y1 ^ 2, d_y2 ^ 2, d_y3 ^ 2, d_y4 ^ 2}

        addps xmm2, xmm3                 ; xmm2 = {l1 ^ 2, 5l2 ^ 2, l3 ^ 2, l4 ^ 2}
        sqrtps xmm2, xmm2                ; xmm2 = {l1, l2, l3, l4}

        addps xmm1, xmm2                 ; sum (xmm1) += {l1, l2, l3, l4}

        add rax, 4 ; i += 4
        cmp rax, rdx
    end_of_four_iteration_if:

    ; Adding all edges lengths to xmm0 (perimeter)
    vhaddps ymm1, ymm1, ymm1      ; ymm1 = {x6 + x7 - x4 + x5 - x6 + x7 - x4 + x5 - x2 + x3 - x0 + x1 - x2 + x3 - x0 + x1}
    vhaddps ymm1, ymm1, ymm1      ; xmm1 = {x4 ~ x7 - x4 ~ x7 - x4 ~ x7 - x4 ~ x7 - x0 ~ x3 - x0 ~ x3 - x0 ~ x3 - x0 ~ x3}
    vpermpd ymm2, ymm1, 0b10101010 ; copying (x4 + x5 + x6 + x7) to all singles of xmm2
    vaddss xmm0, xmm1, xmm2;
    

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

    ret
