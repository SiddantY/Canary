.align 4
.section .text
.globl _start
_start:
    li x8, 0x80001000        
    lw x7, 0(x8)             

    nop
    nop
    nop
    nop
    nop

    li x9, 0x30              
    lw x7, 0(x8)             
    bne x7, x9, snoop_fail

    j snoop_pass

snoop_fail:
    li x10, 0xDEAD           
    j halt

snoop_pass:
    li x10, 0xBEEF           

halt:
    slti x0, x0, -256       
