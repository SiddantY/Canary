# load_line.s:
.align 4
.section .text
.globl _start

    # This program writes to address 0xDEADBEEF only once.

_start:

# Initialize registers
li x6, 0x60000100    # Load the address 0xDEADBEEF into x6

# Perform one store to the address 0xDEADBEEF
li x8, 0xCAFEBABE    # Load value to store into x8
sw x8, 0(x6)         # Store word from x8 to memory address x6

halt:
    slti x0, x0, -256  # Halt the program (custom halt instruction)
