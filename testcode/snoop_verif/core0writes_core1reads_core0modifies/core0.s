.align 4
.section .text
.globl _start
_start:
    li x7, 0x10              
    li x8, 0x80001000        
    sw x7, 0(x8)             

    li x7, 0x20              
    sw x7, 0(x8)             

halt:
    slti x0, x0, -256
