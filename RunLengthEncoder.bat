@ echo off
nasm -Ox -f win64 "RunLengthEncoder.asm"
windres "RunLengthEncoder.rc" -O coff -o "RunLengthEncoder.res"
gcc -fno-stack-protector -no-pie -nostartfiles -s -Wl,--disable-runtime-pseudo-reloc,--image-base,0x00400000 -o "RunLengthEncoder.exe" "RunLengthEncoder.obj" "RunLengthEncoder.res" -lkernel32
