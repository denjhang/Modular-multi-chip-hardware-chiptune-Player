#include <p32xxxx.h>
#ifdef __LIBBUILD__
   .file 1 "crt0.S"
   .loc 1 0
#endif
        ##################################################################
        # Entry point of the entire application
        ##################################################################
        .section .reset,"ax",@progbits
        .set noreorder
        .ent _reset
_reset:
		la		k0, USBLOADER
		jalr	k0
		nop
        la      k0, _startup
        jr      k0                      # Jump to startup code
        nop
  
        .end _reset
        .globl _reset

        ##################################################################
        # Startup code
        ##################################################################
        .section .startup,"ax",@progbits
        .set noreorder
        .ent _startup
_startup:
        ##################################################################
        # Initialize Stack Pointer
        #   _stack is initialized by the linker script to point to the
        #    starting location of the stack in DRM
        ##################################################################
        la      sp,_stack

        ##################################################################
        # Initialize Global Pointer
        #   _gp is initialized by the linker script to point to "middle"
        #   of the small variables region
        ##################################################################
        la      gp,_gp
        
        ##################################################################
        # Call the "on reset" procedure
        ##################################################################
        la      t0,_on_reset
        jalr    t0
        nop

        ##################################################################
        # Clear uninitialized data sections
        ##################################################################
        la      t0,_bss_begin
        la      t1,_bss_end
        b       _bss_check
        nop

_bss_init:      
        sw      zero,0x0(t0)
        sw      zero,0x4(t0)
        sw      zero,0x8(t0)
        sw      zero,0xc(t0)
        addu    t0,16
_bss_check:
        bltu    t0,t1,_bss_init
        nop
        
        ##################################################################
        # Initialize CP0 registers
        ##################################################################
        # Initialize Count register
        ##################################################################
        mtc0    zero,_CP0_COUNT

        ##################################################################
        # Initialize Compare register
        ##################################################################
        li      t2,-1
        mtc0    t2,_CP0_COMPARE

        ##################################################################
        # Initialize EBase register
        ##################################################################
#        la      t1,_ebase_address
#        mtc0    t1,_CP0_EBASE

        ##################################################################
        # Initialize IntCtl register
        ##################################################################
        la      t1,_vector_spacing
        li      t2,0                    # Clear t2 and
        ins     t2,t1,5,5               # shift value to VS field
        mtc0    t2,_CP0_INTCTL

        ##################################################################
        # Initialize CAUSE registers
        # - Enable counting of Count register <DC = 0>
        # - Use special exception vector <IV = 1>
        # - Clear pending software interrupts <IP1:IP0 = 0>
        ##################################################################
        li      t1,0x00800000
        mtc0    t1,_CP0_CAUSE

        ##################################################################
        # Initialize STATUS register
        # - Access to Coprocessor 0 not allowed in user mode <CU0 = 0>
        # - User mode uses configured endianness <RE = 0>
        # - Preserve Bootstrap Exception vectors <BEV>
        # - Preserve soft reset <SR> and non-maskable interrupt <NMI>
        # - CorExtend enabled based on whether CorExtend User Defined
        #   Instructions have been implemented <CEE = Config<UDI>>
        # - Disable any pending interrups <IM7..IM2 = 0, IM1..IM0 = 0>
        # - Disable hardware interrupts <IPL7:IPL2 = 0>
        # - Base mode is Kernel mode <UM = 0>
        # - Error level is normal <ERL = 0>
        # - Exception level is normal <EXL = 0>
        # - Interrupts are disabled <IE = 0>
        ##################################################################
        mfc0    t0,_CP0_CONFIG
        ext     t1,t0,22,1              # Extract UDI from Config register
        sll     t1,t1,17                # Move UDI to Status.CEE location
        mfc0    t0,_CP0_STATUS
        and     t0,t0,0x00580000        # Preserve SR, NMI, and BEV
        or      t0,t1,t0                # Include Status.CEE (from UDI)
        mtc0    t0,_CP0_STATUS

        ##################################################################
        # Call the "on bootstrap" procedure
        ##################################################################
        la      t0,_on_bootstrap
        jalr    t0
        nop

        ##################################################################
        # Initialize Status<BEV> for normal exception vectors
        ##################################################################
        mfc0    t0,_CP0_STATUS
        and     t0,t0,0xffbfffff        # Clear BEV
        mtc0    t0,_CP0_STATUS

        ##################################################################
        # Call main. We do this via a thunk in the text section so that
        # a normal jump and link can be used, enabling the startup code
        # to work properly whether main is written in MIPS16 or MIPS32
        # code. I.e., the linker will correctly adjust the JAL to JALX if
        # necessary
        ##################################################################
        and     a0,a0,0
        and     a1,a1,0
        la      t0,_main_entry
        jr      t0
        nop

        
        .end _startup

        ##################################################################
        # Boot Exception Vector Handler
        # Jumps to _bootstrap_exception_handler
        ##################################################################
        .section .bev_handler,"ax",@progbits
        .set noreorder
        .ent _bev_exception
_bev_exception:
        la      k0,_bootstrap_exception_handler
        jr      k0
        nop

        .end _bev_exception
                        
        ##################################################################
        # General Exception Vector Handler
        # Jumps to _general_exception_handler
        ##################################################################
        .section .gen_handler,"ax",@progbits
        .set noreorder
        .ent _gen_exception
_gen_exception:
        la      k0,_general_exception_context
        jr      k0
        nop

        .end _gen_exception


        .text
        .ent _main_entry
_main_entry:
        ##################################################################
        # Call main
        ##################################################################
        jal main
        nop

        ##################################################################
        # Call exit
        ##################################################################
        jal    exit
        nop

        ##################################################################
        # Just in case, go into infinite loop
        ##################################################################
1:
        b       1b
        nop
        .end _main_entry
        

        ##################################################################
        # Host(PC) Interface support
        ##################################################################
        .ent	_mon_putc
        .global	_mon_putc
_mon_putc:
		addiu	sp, sp, -24
		sw		ra, 20(sp)
		sw		s8, 16(sp)
		addu	s8, sp, zero
        la		t0, PcPutc
        jalr	ra,t0
        nop
        addu	sp, s8, zero
        lw		ra, 20(sp)
        lw		s8, 16(sp)
        addiu	sp, sp, 24
        jr      ra
        nop
        .end	_mon_putc

        .ent	_mon_getc
        .global	_mon_getc
_mon_getc:
		addiu	sp, sp, -24
		sw		ra, 20(sp)
		sw		s8, 16(sp)
		addu	s8, sp, zero
		sw		a0, 24(s8)
        la		t0, PcGetc
        jalr	ra,t0
        nop
        addu	sp, s8, zero
        lw		ra, 20(sp)
        lw		s8, 16(sp)
        addiu	sp, sp, 24
        jr      ra
        nop
        .end	_mon_getc
        
        .globl PcInit
        PcInit = 0x9d07f210

        .globl PcOpen
        PcOpen = 0x9d07f230

        .globl PcPuts
        PcPuts = 0x9d07f250

        .globl PcPutc
        .globl _mon_putc
        PcPutc = 0x9d07f270

        .globl PcGets
        PcGets = 0x9d07f290

        .globl PcGetc
        PcGetc = 0x9d07f2b0

        .globl PcReset
        PcReset = 0x9d07f2d0

        .globl PcSync
        PcSync = 0x9d07f2f0

        .globl PcExit
        PcExit = 0x9d07f310

        .globl PcHexLoad
        PcHexLoad = 0x9d07f330

        .globl PcSvfLoad
        PcSvfLoad = 0x9d07f350

        .globl PcKeySence
        PcKeySence = 0x9d07f370

        .globl PcEp2Read
        PcEp2Read = 0x9d07f390

        .globl PcEp2Write
        PcEp2Write = 0x9d07f3b0

        .globl USBLOADER
        USBLOADER = 0x9d07f3d0

        .globl PcRead
        PcRead = 0x9d07f3f0

        .globl PcWrite
        PcWrite = 0x9d07f410

        .globl PcClose
        PcClose = 0x9d07f430

        .globl PcLseek
        PcLseek = 0x9d07f450

        .globl PcFlush
        PcFlush = 0x9d07f470

