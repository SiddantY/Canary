# load_line.s:
.align 4
.section .text
.globl _start

    # This program loops 1000 times, loading a memory address in each iteration

_start:

# Initialize registers
li x5, 1000        # Loop counter initialized to 1000
li x6, 0x60000100     # Load address of my_data into x6

li x8, 0xDEADBEEF
sw x8, 0(x6)

nop
nop
nop
nop
nop

loop:
    li x8, 0xCAFEBABE
    lw x7, 0(x6)     # Load word from memory address x6 into x7
    addi x5, x5, -1  # Decrement loop counter x5
    sw x8, 0(x6)
    bnez x5, loop    # If x5 is not zero, branch back to loop

halt:
    slti x0, x0, -256   # Halt the program (custom halt instruction)

# Data section
.align 4
.section .data
my_data:
    .word 0x70000000    # Example data at memory location
