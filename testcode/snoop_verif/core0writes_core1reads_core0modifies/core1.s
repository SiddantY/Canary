.align 4
.section .text
.globl _start
_start:
    li x8, 0x80001000        
    lw x9, 0(x8)             

    li x10, 0x20             
    lw x11, 0(x8)            
    bne x11, x10, snoop_fail

    j snoop_pass

snoop_fail:
    li x12, 0xDEAD           
    j halt

snoop_pass:
    li x12, 0xBEEF           

halt:
    slti x0, x0, -256        
