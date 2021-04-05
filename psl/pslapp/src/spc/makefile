
CC = ./wla-spc700.exe
CFLAGS = -ov
LD = ./wlalink.exe
LDFLAGS = -vS

SFILES = ssmpctl.asm
IFILES = 
OFILES = ssmpctl.o

all: $(OFILES) makefile
	$(LD) $(LDFLAGS) linkfile ssmpctl.bin

ssmpctl.o: ssmpctl.asm
	$(CC) $(CFLAGS) ssmpctl.asm

$(OFILES): $(HFILES)

clean:
	rm -f $(OFILES) core *~ ssmpctl.bin ssmpctl.sym

