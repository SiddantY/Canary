# lr_sc_test.s:
.align 4
.section .text
.globl _start

    # This program attempts to atomically store a value into shared memory using LR.W and SC.W

_start:

# Initialize registers
li x5, 0x60000100     # Load address of shared_var into x5
li x6, 42             # Value to store
li x7, 0              # Initialize status register

# Initialize shared_var to 0
li x8, 0
sw x8, 0(x5)

# Atomic store using LR/SC
atomic_store:
    lr.w   x9, 0(x5)       # Load-reserved from shared_var into x9
    sc.w   x10, x6, 0(x5)   # Attempt to store x6 into shared_var
    bnez   x7, atomic_store # If sc.w failed, retry

# Verification loop (optional)
# You can add code here to verify that shared_var now contains 42

addi x11, x10, 0


halt:
    slti x0, x0, -256       # Halt the program (custom halt instruction)

# Data section
.align 4
.section .data
shared_var:
    .word 0                 # Shared variable initialized to 0
