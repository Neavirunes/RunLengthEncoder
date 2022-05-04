@ echo off
nasm -Ox -f win64 "RunLengthEncoder.asm"
windres "RunLengthEncoder.rc" -O coff -o "RunLengthEncoder.res"
gcc -nodefaultlibs -nostartfiles -nostdlib -s -o "RunLengthEncoder.exe" "RunLengthEncoder.obj" "RunLengthEncoder.res" "C:\Windows\System32\kernel32.dll"
