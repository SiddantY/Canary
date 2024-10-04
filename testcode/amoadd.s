# amoadd_test.s:
.align 4
.section .text
.globl _start

    # This program atomically adds a value to shared_var using AMOADD.W

_start:

# Initialize registers
li x5, 0x60000100     # Load address of shared_var into x5
li x6, 5              # Value to add

sw x6, 0(x5)

# Initialize shared_var to 10
li x8, 10



# Atomic addition
amo_add:
    amoadd.w x7, x6, 0(x5)  # Atomically add x6 to shared_var; old value in x7
    
# At this point, shared_var should be 15

halt:
    slti x0, x0, -256       # Halt the program (custom halt instruction)

# Data section
.align 4
.section .data
shared_var:
    .word 0                 # Shared variable initialized to 0
