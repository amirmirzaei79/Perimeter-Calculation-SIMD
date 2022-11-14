segment .text
    global find_perimeter
    extern printf

find_perimeter:
    push rbx
    push r12
    push r13
    push r14
    
    sub rsp, 40

    mov byte [rsp],      '%'
    mov byte [rsp + 1],  'l'
    mov byte [rsp + 2],  'f'
    mov byte [rsp + 3],  10
    mov byte [rsp + 4],  '%'
    mov byte [rsp + 5],  'l'
    mov byte [rsp + 6],  'f'
    mov byte [rsp + 7],  10
    mov byte [rsp + 8],  '%'
    mov byte [rsp + 9],  'l'
    mov byte [rsp + 10], 'f'
    mov byte [rsp + 11], 10
    mov byte [rsp + 12], '%'
    mov byte [rsp + 13], 'l'
    mov byte [rsp + 14], 'f'
    mov byte [rsp + 15], 10
    mov byte [rsp + 16], 0

    ; [rsp] ~ [rsp + 32]: local variables
    ; [rsp] ~ [rsp + 16]:       printf format
    ; [rsp + 17] ~ [rsp + 32]:  memory to work with XMMs (packed to scalar)
    ;
    ; [rsp + 40]:  previous r14
    ; [rsp + 48]:  previous r13
    ; [rsp + 56]:  previous r12
    ; [rsp + 64]:  previous rbx
    ;
    ; [rsp + 72]:  return address
    ;
    ; rdi:         x coordinates array (input) - 32_bit floating point array
    ; rsi:         y coordinates array (input) - 32_bit floating point array
    ; rdx:         number of points    (input) - 32_bit signed int
    ;
    ; rbx:         main loop iterator (array index)
    ; r12:         number of points (changes during code)
    ; r13:         x coordiantes array
    ; r14:         y coordinates array
    ;
    ; xmm15:       perimeter
    ; xmm14:       sum of first 4 * k edge lengths (each part sum of 1/4 of edges) - changes after SIMD section (four_iteration_loop)
    ;
    ; xmm0 ~ xmm3: printf inputs
    
    mov r12, rdx
    mov rbx, 1
    mov r13, rdi
    mov r14, rsi

    xorps xmm14, xmm14 ; setting xmm14 to zeros {0, 0, 0, 0}
    movss xmm15, xmm14 ; setting xmm15 (perimeter) to zero (scalar)

    sub r12, 4 ; r12 = n - 4
    jle end_of_four_iteration_loop
    four_iteration_loop: ; iterating over array doing calculations 4 by 4
        movups xmm13, [r13 + 4 * rbx]     ; xmm13 = {x[i], x[i + 1], x[i + 2], x[i + 3]}
        subps xmm13, [r13 + 4 * rbx - 4]  ; xmm13 = {d_x1, d_x2, d_x3, d_x4} = {x[i] - x[i - 1], x[i + 1] - x[i], x[i + 2] - x[i + 1], x[i + 3] - x[i + 2]}
        mulps xmm13, xmm13                ; xmm13 = {d_x1 ^ 2, d_x2 ^ 2, d_x3 ^ 2, d_x4 ^ 2}

        movups xmm12, [r14 + 4 * rbx]     ; xmm12 = {y[i], y[i + 1], y[i + 2], y[i + 3]} 
        subps xmm12, [r14 + 4 * rbx - 4]  ; xmm12 = {d_y1, d_y2, d_y3, d_y4} = {y[i] - y[i - 1], y[i + 1] - y[i], y[i + 2] - y[i + 1], y[i + 3] - y[i + 2]}
        mulps xmm12, xmm12                ; xmm12 = {d_y1 ^ 2, d_y2 ^ 2, d_y3 ^ 2, d_y4 ^ 2}

        addps xmm13, xmm12                ; xmm13 = {l1 ^ 2, 5l2 ^ 2, l3 ^ 2, l4 ^ 2}
        sqrtps xmm13, xmm13               ; xmm13 = {l1, l2, l3, l4}
        
        addps xmm14, xmm13                ; sum += {l1, l2, l3, l4}

        ; printing edges lengths using printf
        movups [rsp + 17], xmm13
        cvtss2sd xmm0, [rsp + 17]
        cvtss2sd xmm1, [rsp + 21]
        cvtss2sd xmm2, [rsp + 25]
        cvtss2sd xmm3, [rsp + 29]
        mov rdi, rsp
        mov rax, 4 ; setting rax (al) to number of vector inputs
        call printf

        add rbx, 4 ; i += 4
        cmp rbx, r12
        jl four_iteration_loop

    ; Adding all edges lengths to xmm0 (perimeter)
    movups [rsp + 17], xmm14
    movss xmm15, [rsp + 17]
    addss xmm15, [rsp + 21]
    addss xmm15, [rsp + 25]
    addss xmm15, [rsp + 29]

    end_of_four_iteration_loop:

    mov byte [rsp + 4], 0 ; changing printf format to print only one number

    add r12, 4 ; r12 = n
    cmp rbx, r12
    jge end_of_one_iteration_loop
    one_iteration_loop: ; iterating over remaining elements 1 by 1
        movss xmm0, [r13 + 4 * rbx]      ; xmm0 = x[i]
        subss xmm0, [r13 + 4 * rbx - 4]  ; xmm0 = d_x = x[i] - x[i - 1]
        mulss xmm0, xmm0                 ; xmm0 = d_x ^ 2
        movss xmm1, [r14 + 4 * rbx]      ; xmm1 = y[i]
        subss xmm1, [r14 + 4 * rbx - 4]  ; xmm1 = d_y = y[i] - y[i - 1]
        mulss xmm1, xmm1                 ; xmm1 = d_y ^ 2   
        addss xmm0, xmm1                 ; xmm0 = length ^ 2
        sqrtss xmm0, xmm0                ; xmm0 = length

        addss xmm15, xmm0                ; xmm15 (perimeter) += length
        
        ; printing edge length using printf function
        cvtss2sd xmm0, xmm0
        mov rdi, rsp
        mov rax, 1 ; setting rax (al) to number of vector inputs 
        call printf

        inc rbx
        cmp rbx, r12
        jl one_iteration_loop        

    end_of_one_iteration_loop:

    ; Calculations for last edge
    movss xmm0, [r13]                ; xmm0 = x[0]
    subss xmm0, [r13 + 4 * r12 - 4]  ; xmm0 = d_x = x[0] - x[n - 1]
    mulss xmm0, xmm0                 ; xmm0 = d_x ^ 2
    movss xmm1, [r14]                ; xmm1 = y[0]
    subss xmm1, [r14 + 4 * r12 - 4]  ; xmm1 = d_y = y[0] - y[n - 1]
    mulss xmm1, xmm1                 ; xmm1 = d_y ^ 2   
    addss xmm0, xmm1                 ; xmm0 = length ^ 2
    sqrtss xmm0, xmm0                ; xmm0 = length

    addss xmm15, xmm0
        
    ; printing edge length using printf function
    cvtss2sd xmm0, xmm0
    mov rdi, rsp
    mov rax, 1 ; setting rax (al) to number of vector inputs 
    call printf

    movss xmm0, xmm15 ;putting output in xmm0
    
    add rsp, 40 ; clearing local variables from stack

    pop r14
    pop r13
    pop r12
    pop rbx

    ret
