@echo off

if not exist scpuh.s goto _exit1
if not exist scpuctl.s goto _exit1
cls
del scpuctl.bin
del scpuh_.bin
del scpuctl.lst
del scpuctl_.bin
as68k -s scpuh.s nul scpuh
sload scpuh.s28 scpuh_.bin > nul
del scpuh.s28
as68k -s scpuctl.s scpuctl.lst scpuctl
sload scpuctl.s28 scpuctl_.bin > nul
del scpuctl.s28
copy /b scpuh_.bin+scpuctl_.bin scpuctl.bin
:_exit1
