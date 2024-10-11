.align 4
.section .text
.globl _start
_start:
    li x7, 0x90
    li x8, 0x80001000
    sw x7, 0(x8)

    nop
    nop
    nop
    nop
    nop

    li x7, 0xA0
    sw x7, 0(x8)

halt:
    slti x0, x0, -256
