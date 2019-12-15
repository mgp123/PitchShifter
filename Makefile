rwmake: src/main.c src/rw_audio.c src/rw_audio.h src/fft.h
	gcc src/main.c src/fft.c src/rw_audio.c src/rw_audio.h src/fft.h -o main -lsndfile -lm