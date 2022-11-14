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


## More Details:
**main.C** implements main function, reads the input, calls the **find_perimeter** function and writes it's result to output.

Body of the **find_perimeter** function is implemented in **find_perimeter.asm** file. This function receives the x,y coordinates of the polygon vertices and returns the perimeter of the polygon. The first argument is a pointer to an array of double-precision floating-point numbers representing the x-coordinates of the polygon vertices . Similarly, the second argument gives the y-coordinates of the vertices. The third and final argument is the number of the vertices which is the same as the size of the input arrays. The function computes the length of each polygon edge (including the edge between the last and the first vertex) and if the folder container "_print_edge" in name, prints them by calling the printf function from the C standard library. Then it returns the perimeter of the polygon as a floating point number.

Each folder contains a make file to compile the code inside and create **main.out** binary executable that reads vertices coordinates and prints out polygon's perimeter (and length of each edge if specified in folder name).
