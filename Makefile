ASM = $(wildcard src/*.asm)
ASM_O = $(ASM:.asm=.o)

main: ${ASM} src/*.c src/*.h 
	make ${ASM_O}
	gcc src/*.c src/*.h src/*.o -o main -lsndfile -lm

%.o: %.asm
	nasm -f elf64 $<

clean:
	-rm -f src/*.o main