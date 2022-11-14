# Perimeter Calculation SIMD

The codes in this repository implement a function with C calling convention in amd64 assembly (Intel Syntax), and the main code takes a coordinates of vertices of a polygon and calculates polygon's perimeter using the function written in assembly and returns it. SIMD does few calculations (exact number depends on instruction set) in parallel (with a single instruction, calculates results for multiple data; hence the name) to speed up calculations.

All folders contain a make file to compile them.

The code inside each folder returns the same results but calculates it using a different set of instructions or has a different calling convention than others.

## Folders Notation:

First part of each folder's name signifies the instruction set that is used to calculate the perimeter.

* FPU utilizes the x87 co-processor instruction set (which is not SIMD)
* SSE2 utilizes SSE2 instruction set
* AVX2 utilizes AVX2 (AVX256) instruction set

The second part shows whether the function uses 32 bit or 64 bit calling convention. Needless to say that compiling 32-bit codes will result in an ELF32 executable and compiling 64-bit codes results will be an ELF64 executable.

If the name has a third part (_print_edge) it means assembly code calls stdlib's printf function to print length of each edge.

