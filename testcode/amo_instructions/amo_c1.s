# Core 2 Code - thread2.S
.align 4
.section .text
.globl _start

_start_core2:
    # Load initial value into register
    li t4, 3                  # t4 = 3 (value to XOR)
    li t5, 10                 # Number of iterations

loop2:
    # Perform AMOXOR (Atomic XOR Word)
    amoxor.w t6, t4, (shared_data)  # Atomic XOR: shared_data = shared_data ^ t4, t6 gets old value

    # Decrement loop counter and branch if not zero
    addi t5, t5, -1
    bnez t5, loop2

# Custom Halt Instruction (halt the program)
slti x0, x0, -256          # Halt instruction

# Data section
.align 4
.section .data
my_data:
    .word 0x70000000    # Example data at memory location
