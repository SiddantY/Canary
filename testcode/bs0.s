bs0.s:
.align 4
.section .text
.globl _start
_start:
    li x7, 0xA               
    li x8, 0x80001000        
    sw x7, 0(x8)             

    
    lw x9, 0(x8)             

halt:
    slti x0, x0, -256        