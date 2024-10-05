# Core 1 Code - thread1.S
.align 4
.section .text
.globl _start


_start:
    # Initialize shared_data to 0
    la t0, shared_data
    sw zero, 0(t0)

    # Load initial value into register
    li t1, 2                  # t1 = 2 (value to be added atomically)
    li t2, 10                 # Number of iterations

loop1:
    # Perform AMOADD (Atomic Add Word)
    amoadd.w t3, t1, (shared_data)  # Atomic add: shared_data = shared_data + t1, t3 gets old value

    # Decrement loop counter and branch if not zero
    addi t2, t2, -1
    bnez t2, loop1

# Custom Halt Instruction (halt the program)
slti x0, x0, -256          # Halt instruction

# Data section
.align 4
.section .data
my_data:
    .word 0x70000000    # Example data at memory location
