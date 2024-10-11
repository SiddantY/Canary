.align 4
.section .text
.globl _start
_start:
    li x7, 0x40              
    li x8, 0x80001000        
    sw x7, 0(x8)             

    nop
    nop
    nop
    nop
    nop

    li x10, 0x50             
    lw x7, 0(x8)             
    bne x7, x10, snoop_fail

    j snoop_pass

snoop_fail:
    li x11, 0xDEAD           
    j halt

snoop_pass:
    li x11, 0xBEEF           

halt:
    slti x0, x0, -256
