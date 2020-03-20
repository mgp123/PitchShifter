#!/bin/bash
echo "Instalando librería sndfile:"
make install
echo "Compilando trabajo"
make
echo "Creando ejemplo stretch"
./main stretch ./sonidos/Maple_mono.wav 2
echo "Creando ejemplo repitch"
./main repitch ./sonidos/bowie_mono.wav 2
echo "Creando ejemplo reverb"
./main reverb ./sonidos/beethoven_mono.wav ./impulse_response/ir1.wav
echo "Creando ejemplo vocoder"
echo "falta agregar ejemplo"