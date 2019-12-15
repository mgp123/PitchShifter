rwmake: main.c rw_audio.c rw_audio.h fft.h
	gcc main.c fft.c rw_audio.c rw_audio.h fft.h -o main -lsndfile -lm