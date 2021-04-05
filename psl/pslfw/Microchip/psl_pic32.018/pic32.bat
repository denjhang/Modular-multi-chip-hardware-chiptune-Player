@if not exist psl.hex goto _exit
pic32cons.exe -dev psl.hex %1
:_exit
