@echo off

if not exist cpuctl.asm goto _exit1
del cpuctl.lst
del cpuctl.bin
nesasm -s -raw cpuctl.asm
ren cpuctl.nes *.bin
:_exit1
