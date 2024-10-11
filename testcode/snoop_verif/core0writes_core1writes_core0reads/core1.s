.align 4
.section .text
.globl _start
_start:
    li x8, 0x80001000        
    li x9, 0x50              
    sw x9, 0(x8)             

halt:
    slti x0, x0, -256        
