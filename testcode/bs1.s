bs1.s:
.align 4
.section .text
.globl _start
_start:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

    li x10, 0x80001000        
    lw x7, 0(x10)             

    li x8, 0xA               
    bne x7, x8, snoop_fail   

    j snoop_pass             

snoop_fail:
    li x10, 0xDEAD            
    j halt

snoop_pass:
    li x10, 0xBEEF            
    j halt

halt:
    slti x0, x0, -256        