ASM = $(wildcard src/*.asm)
ASM_O = $(ASM:.asm=.o)

TESTER_C =$(subst src/main.c,,$(wildcard src/*.c))

main: ${ASM} src/*.c src/*.h 
	make ${ASM_O}
	gcc src/*.c src/*.h src/*.o -o main -lsndfile -lm

%.o: %.asm
	nasm -f elf64 $<

clean:
	-rm -f src/*.o main test

tester: tester/test_reverb.c ${ASM} ${TESTER_C} src/*.h 
	make ${ASM_O}
	gcc tester/test_reverb.c ${TESTER_C}  src/*.h src/*.o -o test -lsndfile -lm
