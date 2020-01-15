
.PHONY:tester test_target
ASM = $(wildcard src/*.asm)
ASM_O = $(ASM:.asm=.o)

TESTER_C_FILES =$(subst src/main.c,,$(wildcard src/*.c))
TEST_C = $(wildcard tester/*.c)

main: ${ASM} src/*.c src/*.h 
	make ${ASM_O}
	gcc src/*.c src/*.h src/*.o -o main -lsndfile -lm

%.o: %.asm
	nasm -f elf64 $<

clean:
	-rm -f src/*.o main $(TEST_C:tester/%.c=%)

tester:
	make ${ASM_O}
	@$(foreach test,$(TEST_C), make test_target TEST_TARGET=$(test);)

TEST_TARGET = "none"
TEST_NAME = $(TEST_TARGET:tester/%.c=%)
test_target: $(TEST_TARGET) ${ASM} ${TESTER_C_FILES} src/*.h 
	gcc $(TEST_TARGET) ${TESTER_C_FILES}  src/*.h src/*.o -o $(TEST_NAME) -lsndfile -lm
