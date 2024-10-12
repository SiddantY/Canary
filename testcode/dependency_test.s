dependency_test.s:
.align 4
.section .text
.globl _start
    # This program consists of small snippets
    # containing RAW, WAW, and WAR hazards

    # This test is NOT exhaustive
_start:





auipc x7, 0
SW x1, 4(x7)

# RAW
# mul x3, x1, x2
add x5, x3, x4

# WAW
# mul x6, x7, x8
add x6, x9, x10

# WAR
# mul x11, x12, x13
add x12, x1, x2

halt:
    slti x0, x0, -256
