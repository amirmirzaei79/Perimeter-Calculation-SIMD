GCC_OPTIONS= -m32
NASM_OPTIONS= -f elf

main.out: main.c find_perimeter.o
	gcc -o main.out $(GCC_OPTIONS) main.c find_perimeter.o

find_perimeter.o: find_perimeter.asm
	nasm $(NASM_OPTIONS) find_perimeter.asm

clean:
	rm main.out find_perimeter.o