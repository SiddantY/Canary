.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Note that the comments in this file should not be taken as
    # an example of good commenting style!!  They are merely provided
    # in an effort to help you understand the assembly style.

    # all arithmetic
auipc x7, 0     # 6000_0000

nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop



OR x4, x4, x4
LBU x4, 4(x7)
SLL x1, x0, x0
AND x4, x1, x4
SRL x1, x3, x3
AUIPC x4, 21
OR x1, x4, x1
XOR x4, x2, x4
LH x1, 16(x7)
SRL x0, x2, x4
ORI x1, x2, 3
SLL x4, x0, x3
ADDI x3, x2, 74
LHU x3, 12(x7)
SLT x0, x1, x0
XOR x0, x4, x0
LH x2, 0(x7)

#slti x0, x0, -256 # this is the magic instruction to end the simulation

XOR x4, x2, x0
XOR x1, x3, x0
OR x1, x2, x3
AUIPC x2, 14
SRAI x1, x1, 30
LHU x3, 0(x7)
LBU x3, 16(x7)
ADDI x4, x4, 16
ADDI x1, x1, 33
AND x0, x2, x3
AUIPC x3, 16
SRL x4, x1, x3
SRAI x2, x2, 2
SUB x4, x3, x3
AUIPC x1, 17
ADDI x3, x3, -23
SLTI x0, x0, 32
SLT x3, x2, x2
ANDI x0, x4, 52
SLL x3, x1, x1
ADDI x3, x2, 14
AUIPC x0, 18
ADDI x0, x3, -71
SLTIU x1, x2, 30
SRL x0, x1, x3
LH x3, 16(x7)
SRA x2, x0, x2
AND x1, x3, x0
LBU x2, 12(x7)
SLT x3, x0, x0
SUB x1, x0, x1
LH x4, 4(x7)
ADDI x2, x0, -31
XORI x4, x4, 2
ADD x3, x1, x0
SLTI x1, x2, 28
XORI x0, x2, 77
LBU x0, 16(x7)
LBU x3, 8(x7)
SLL x4, x3, x0
SRL x0, x2, x1
SLTI x0, x1, 70
OR x3, x3, x0
XORI x1, x1, -94
OR x3, x0, x4
LBU x0, 12(x7)
AND x3, x1, x1
LBU x2, 8(x7)
ORI x1, x3, -39
SLTU x1, x3, x2
SLTU x2, x2, x4
SLTIU x0, x3, 60
SRAI x0, x3, 14
LH x2, 20(x7)
ADD x0, x0, x0
LB x3, 0(x7)
XORI x0, x1, -8
ADD x2, x2, x4
ADDI x1, x3, -34
LH x2, 4(x7)
ADDI x1, x3, -58
SLT x3, x3, x3
SUB x2, x2, x0
LHU x3, 16(x7)
AND x4, x4, x0
LH x1, 12(x7)
XOR x4, x4, x2
XOR x1, x1, x3
SRAI x1, x3, 21
OR x1, x0, x0
LHU x1, 20(x7)
ADD x4, x1, x1
AND x4, x1, x0
ORI x0, x3, -89
LBU x0, 4(x7)
XORI x0, x0, 6
ADD x3, x4, x4
SLLI x4, x4, 5
LB x4, 16(x7)
SRA x4, x1, x4
SUB x3, x2, x1
LH x0, 8(x7)
ADD x3, x4, x2
SLTIU x3, x3, 45
SLL x1, x4, x2
SRL x3, x4, x1
LB x2, 20(x7)
SLLI x1, x2, 22
LHU x1, 4(x7)
AND x1, x3, x0
ADD x0, x2, x2
LBU x1, 8(x7)
SRLI x0, x1, 1
OR x3, x4, x0
AUIPC x0, 0
SLL x3, x4, x0
SLTU x4, x0, x4
ADDI x0, x2, 16
SUB x4, x0, x4
XOR x2, x1, x0
SRL x4, x2, x0
ADDI x3, x1, 85
SRLI x2, x3, 17
OR x3, x0, x0
LB x3, 20(x7)
SRL x0, x1, x4
SLL x2, x3, x4
SUB x2, x3, x1
SLTIU x3, x0, 19
XOR x1, x4, x0
XOR x3, x1, x2
XOR x3, x3, x2
ANDI x0, x0, -31
SRL x3, x1, x4
XOR x4, x4, x3
ANDI x4, x0, -99
OR x3, x1, x3
XORI x0, x0, -27
LUI x4, 28
SLTI x4, x3, -29
LBU x2, 16(x7)
XOR x0, x2, x3
AUIPC x4, 3
AUIPC x1, 8
LB x4, 4(x7)
LHU x3, 16(x7)
OR x0, x1, x2
LH x3, 4(x7)
SLT x3, x1, x4
SLLI x1, x4, 26
LBU x4, 8(x7)
ORI x3, x0, 2
SRL x3, x4, x3
SLTIU x1, x4, -56
OR x3, x2, x4
SLL x2, x4, x0
SRL x0, x3, x2
AND x2, x0, x4
SLLI x2, x2, 25
XOR x0, x0, x4
SLTI x4, x4, -54
ADD x3, x1, x3
OR x3, x0, x1
SRAI x1, x4, 14
SRL x0, x1, x4
SLTU x0, x3, x2
LHU x0, 16(x7)
LHU x4, 4(x7)
SRL x2, x2, x0
LHU x1, 4(x7)
SLLI x0, x1, 5
SLLI x4, x4, 23
ANDI x2, x4, -7
LH x4, 4(x7)
LH x4, 0(x7)
SRLI x4, x1, 5
SRA x0, x3, x3
XORI x2, x1, 38
ADD x0, x0, x1
ORI x1, x2, -17
SRAI x0, x1, 3
ADDI x3, x0, 61
SRA x4, x1, x2
SLLI x1, x2, 25
LH x4, 12(x7)
SRL x1, x4, x2
ANDI x1, x2, -86
LBU x3, 12(x7)
LUI x2, 19
ADD x2, x1, x4
SRL x3, x2, x4
LH x1, 8(x7)
LHU x2, 16(x7)
XOR x3, x4, x4
LB x3, 8(x7)
SRAI x2, x0, 4
SLTI x1, x3, -15
ANDI x4, x4, -21
AUIPC x1, 24
SRL x4, x0, x0
LHU x4, 12(x7)
AND x2, x0, x2
XOR x3, x2, x4
LUI x3, 17
SLT x2, x1, x3
AUIPC x2, 19
SRLI x1, x4, 23
SUB x1, x2, x1
SLTU x4, x3, x2
XOR x4, x4, x4
SLTU x3, x4, x4
XOR x4, x1, x2
SLTI x2, x3, 63
SLL x0, x0, x3
LBU x0, 8(x7)
SLT x0, x4, x3
XORI x2, x3, -31
AUIPC x0, 0
SRL x0, x3, x2
AUIPC x1, 1
AUIPC x4, 1
SRA x2, x1, x2
SLT x2, x1, x4
LHU x1, 20(x7)
LH x3, 8(x7)
XORI x4, x3, 73
SRLI x2, x1, 12
SLLI x4, x1, 6
XOR x2, x4, x2
SLTIU x4, x0, -81
ORI x1, x1, -81
LB x3, 4(x7)
AUIPC x3, 28
SUB x0, x1, x0
XORI x1, x3, -30
LH x3, 16(x7)
ADD x1, x3, x2
ADDI x2, x2, -57
ADD x2, x0, x0
SLTI x0, x2, 52
SLTI x1, x1, -83
SLTU x0, x2, x4
SLLI x3, x2, 2
SRAI x3, x1, 4
SLL x2, x0, x2
SRA x0, x0, x2
LHU x0, 20(x7)
XOR x0, x2, x0
AUIPC x3, 30
AND x3, x1, x2
SLTU x1, x4, x0
SRLI x3, x1, 21
SLTIU x4, x2, -75
LBU x0, 4(x7)
SRA x0, x2, x0
SRAI x0, x0, 1
SRA x3, x3, x3
SLLI x3, x0, 5
SLL x2, x3, x3
SRAI x2, x4, 27
ANDI x1, x2, -47
ANDI x1, x4, -62
SRLI x4, x1, 4
LB x3, 4(x7)
SLL x1, x2, x2
SLLI x1, x4, 24
SRAI x3, x0, 14
LUI x3, 3
LB x3, 4(x7)
SRLI x3, x1, 15
XOR x2, x1, x2
SLT x4, x2, x2
ORI x0, x2, 72
XORI x4, x4, 70
SLLI x4, x0, 2
SRAI x3, x2, 9
AND x3, x0, x4
SLL x0, x0, x2
LUI x0, 26
SRL x3, x4, x3
ANDI x2, x1, 22
LH x0, 4(x7)
SLTI x2, x4, 4
SLT x1, x4, x4
SRL x1, x2, x1
AND x2, x1, x4
AUIPC x3, 14
AUIPC x4, 17
SRA x3, x4, x3
SRAI x2, x3, 11
XOR x1, x3, x4
SRL x1, x1, x0
ORI x3, x0, 97
AUIPC x4, 24
SLT x1, x1, x2
ADD x3, x2, x3
XORI x4, x4, -70
LBU x4, 12(x7)
SUB x4, x3, x3
XORI x4, x2, 34
SRAI x0, x4, 5
ORI x0, x0, 7
OR x2, x0, x0
SLLI x2, x4, 21
SUB x4, x2, x0
SLTU x1, x0, x1
ANDI x3, x0, -14
XORI x4, x0, -20
ADD x2, x2, x2
SUB x0, x4, x4
LUI x1, 6
LB x4, 12(x7)
XOR x0, x3, x2
SRL x4, x0, x2
LH x3, 4(x7)
LHU x1, 0(x7)
ADDI x2, x1, 41
SLTI x0, x1, -1
ADDI x4, x3, 79
SRA x3, x3, x0
SLLI x0, x3, 9
SLLI x2, x0, 31
SLL x1, x0, x2
SLTIU x4, x4, -6
SLT x3, x0, x1
OR x4, x2, x3
LH x4, 20(x7)
XORI x0, x4, 14
SLTI x2, x2, -57
LB x2, 12(x7)
ADDI x3, x4, 37
ORI x0, x2, -13
SLTI x4, x0, -51
AND x1, x0, x0
SLT x1, x0, x4
AND x4, x0, x0
AND x4, x2, x3
LBU x1, 8(x7)
ORI x2, x1, -32
SLT x3, x0, x4
SRAI x1, x2, 14
SLLI x4, x0, 18
XOR x3, x2, x2
AUIPC x0, 11
SUB x4, x2, x3
SLTU x2, x4, x0
SLLI x0, x1, 8
SLTIU x0, x1, 78
LUI x0, 3
ADDI x4, x3, -7
SLTIU x0, x1, -85
XOR x0, x1, x4
LB x2, 0(x7)
SLTU x1, x0, x0
SLTU x1, x3, x3
OR x2, x4, x1
SRL x3, x2, x2
ANDI x2, x2, 71
SRA x1, x3, x4
LBU x4, 0(x7)
SRL x1, x2, x4
LB x4, 20(x7)
SLT x3, x0, x1
AUIPC x0, 15
SRLI x2, x1, 23
ORI x3, x2, 89
LH x0, 20(x7)
AND x2, x0, x4
ORI x1, x3, -5
SLTIU x0, x2, 59
ANDI x0, x3, -100
SUB x1, x4, x4
SLT x1, x2, x0
ADD x3, x0, x3
SLLI x1, x1, 19
SLTI x2, x4, -45
AUIPC x2, 2
SRAI x0, x0, 12
SLT x4, x3, x1
AND x0, x2, x0
ADD x3, x3, x4
SLT x0, x2, x2
SRAI x0, x3, 19
AUIPC x2, 5
LHU x3, 8(x7)
SLTU x0, x4, x1
SLL x0, x0, x2
SRAI x0, x3, 8
SLTU x1, x0, x3
AUIPC x3, 17
SLLI x1, x0, 2
SLTU x2, x0, x1
ANDI x4, x1, -97
SLTI x2, x4, -25
SLTU x3, x2, x4
AND x4, x4, x4
XOR x4, x2, x2
SLLI x4, x0, 11
SLLI x4, x4, 30
SLTI x4, x2, -77
SRLI x3, x4, 6
OR x3, x0, x4
LB x2, 12(x7)
SLTIU x0, x4, -47
SLT x2, x0, x4
SUB x4, x1, x2
ORI x1, x0, 5
SLLI x1, x2, 10
LHU x1, 8(x7)
SLTU x2, x2, x3
ADD x3, x1, x1
SRA x0, x4, x2
SRAI x0, x4, 1
ANDI x0, x2, 73
LHU x3, 0(x7)
LHU x2, 4(x7)
AND x3, x2, x1
AND x3, x3, x4
ADDI x2, x1, 80
SRLI x1, x3, 12
LB x3, 8(x7)
OR x3, x3, x2
OR x4, x3, x4
LUI x3, 31
SRAI x0, x4, 3
SLTU x3, x2, x0
ADD x4, x3, x1
ORI x0, x0, 67
XOR x2, x4, x4
SRL x4, x1, x1
SRL x4, x2, x1
LBU x1, 12(x7)
LHU x0, 8(x7)
ADDI x0, x0, -71
SRAI x3, x3, 23
SRLI x2, x0, 24
LBU x2, 16(x7)
XOR x3, x4, x2
SRL x1, x4, x0
SLLI x3, x2, 29
LH x0, 12(x7)
SLT x2, x3, x3
XORI x3, x3, 94
SLTI x2, x2, -87
OR x4, x3, x2
SLTIU x1, x3, 7
SRAI x0, x0, 13
LHU x0, 20(x7)
SRLI x3, x1, 5
SLT x2, x2, x4
SLL x4, x1, x0
SRA x0, x1, x0
SLTI x3, x2, 55
LB x3, 8(x7)
ORI x4, x0, 71
SRLI x1, x1, 15
OR x4, x2, x1
SUB x0, x4, x3
SRA x1, x0, x0
ORI x3, x2, 63
SLTIU x2, x4, -67
OR x0, x0, x0
ORI x2, x4, 91
OR x1, x4, x2
ADDI x0, x3, 96
LBU x1, 16(x7)
AUIPC x4, 20
LUI x1, 8
LHU x4, 20(x7)
ADD x1, x4, x0
SRAI x0, x2, 0
ADD x2, x4, x4
SRL x3, x0, x3
SUB x0, x3, x1
LBU x3, 12(x7)
ORI x2, x3, -10
SRLI x1, x3, 30
AND x0, x3, x1
ADD x0, x4, x2
SRLI x4, x3, 20
AUIPC x4, 20
AUIPC x3, 29
SLTU x4, x0, x3
LBU x3, 16(x7)
XOR x1, x4, x2
AUIPC x2, 4
SLTIU x2, x0, 66
SLTI x4, x0, -2
SLL x2, x4, x2
LBU x4, 16(x7)
SLTIU x0, x2, 16
SLT x3, x0, x2
LUI x4, 1
ANDI x3, x0, 76
ORI x0, x4, -39
ORI x3, x0, 72
SLL x4, x1, x1
AUIPC x2, 6
OR x3, x0, x2
ORI x0, x0, 34
SLL x4, x2, x2
LUI x4, 31
XOR x0, x0, x0
SRAI x4, x4, 1
LB x1, 0(x7)
SRAI x1, x1, 7
ORI x3, x0, -3
SLL x2, x4, x2
SLTU x3, x0, x3
XOR x3, x3, x0
AUIPC x3, 7
SLLI x1, x1, 9
LHU x3, 20(x7)
XORI x3, x4, 96
LUI x4, 10
XOR x2, x1, x1
SLTI x2, x4, 31
ADD x3, x4, x1
SRL x1, x3, x0
SLTI x2, x1, 32
LH x2, 8(x7)
SUB x2, x3, x4
XORI x1, x4, 36
ORI x2, x3, -34
SLL x3, x1, x3
SRAI x1, x1, 8
SRA x2, x1, x1
SLT x4, x1, x4
ORI x4, x3, 90
LB x4, 16(x7)
SLLI x4, x3, 1
SRLI x0, x0, 4
AUIPC x3, 22
ANDI x1, x2, -91
SLTI x2, x4, -20
SRAI x3, x2, 3
SLT x0, x4, x0
SRLI x0, x0, 2
LUI x4, 8
LBU x1, 16(x7)
AND x0, x2, x2
SLT x2, x2, x4
XORI x2, x3, -28
SLTU x3, x3, x2
SLLI x0, x1, 3
ORI x0, x4, -26
OR x0, x3, x0
OR x0, x1, x3
SRA x0, x2, x1
LB x4, 8(x7)
SLLI x0, x2, 13
SUB x2, x0, x4
XORI x1, x4, -31
LB x2, 4(x7)
SLLI x4, x1, 3
SLT x1, x2, x1
ADD x2, x4, x2
SRAI x3, x2, 5
SLT x1, x1, x2
ANDI x2, x3, -24
SLLI x0, x2, 24
SUB x0, x4, x2
SLTU x1, x3, x2
SLL x4, x0, x4
SLT x1, x0, x1
SLLI x0, x0, 2
SLTU x4, x2, x1
ANDI x3, x3, -47
SRA x2, x1, x1
SLTIU x3, x3, 82
AUIPC x0, 18
SRLI x1, x4, 28
SRAI x4, x0, 25
LHU x2, 0(x7)
SLT x0, x3, x2
ANDI x3, x3, -6
SRA x0, x0, x0
ADDI x0, x0, -52
SLL x2, x0, x2
SLTU x2, x0, x3
AND x2, x0, x3
SLT x3, x4, x1
SLL x4, x4, x3
SRLI x0, x1, 20
OR x2, x4, x0
SRL x4, x0, x1
SLTI x2, x0, 31
OR x2, x3, x2
OR x3, x3, x1
XOR x3, x1, x3
SRL x3, x4, x4
ADD x4, x1, x4
SLL x4, x1, x2
ANDI x0, x0, -24
XORI x3, x1, -76
ORI x4, x2, -95
XORI x4, x1, -33
OR x2, x3, x2
SLLI x2, x2, 31
SLTI x4, x1, 29
XORI x4, x0, -83
SRLI x3, x2, 8
SRL x4, x2, x3
SLL x3, x2, x1
SRLI x3, x1, 10
SLLI x1, x2, 25
ADD x1, x0, x3
SRA x2, x1, x4
ADD x1, x3, x4
LHU x2, 16(x7)
XOR x3, x3, x2
SLLI x4, x3, 26
SLL x4, x3, x3
LUI x3, 22
SRA x4, x1, x0
SLT x3, x3, x1
SRL x4, x3, x3
XOR x2, x4, x3
SRA x0, x3, x4
SLTI x1, x3, 19
SLL x4, x0, x2
ORI x3, x2, 18
XOR x2, x1, x2
SLLI x0, x0, 16
ADDI x1, x4, -52
SRA x3, x2, x4
AUIPC x4, 10
ANDI x4, x4, -93
SLL x3, x3, x3
ADDI x2, x2, 35
SLLI x4, x2, 23
XOR x0, x3, x1
SLLI x3, x1, 23
SLTIU x4, x1, 47
ADDI x1, x2, 81
SLLI x1, x0, 10
SRAI x0, x2, 28
SLL x4, x0, x0
SLTU x2, x4, x0
AUIPC x2, 9
OR x0, x1, x4
LB x1, 12(x7)
SRAI x4, x0, 9
SRA x1, x2, x3
AUIPC x2, 3
AND x2, x1, x4
SLTIU x3, x0, 53
ADDI x3, x1, 35
XOR x1, x1, x4
ANDI x2, x4, 9
ADDI x4, x2, -39
SRL x3, x1, x4
XOR x2, x0, x0
SLLI x0, x3, 8
XOR x4, x2, x1
SLLI x1, x1, 2
ANDI x1, x0, 9
LH x1, 12(x7)
XOR x4, x0, x1
SRA x4, x2, x0
ADDI x1, x1, 58
LUI x4, 28
SRAI x2, x3, 6
SLLI x3, x4, 15
SLLI x3, x3, 9
LHU x1, 8(x7)
SLT x1, x3, x4
SRLI x3, x3, 9
ADD x0, x2, x1
XORI x1, x0, 86
LHU x4, 8(x7)
LHU x0, 8(x7)
SUB x3, x2, x1
SRAI x1, x4, 26
SRAI x4, x2, 0
LUI x3, 2
SRL x3, x1, x2
XORI x1, x2, -72
ANDI x4, x3, -61
XORI x2, x1, -25
SRA x2, x1, x2
ADDI x2, x1, -100
SRLI x3, x3, 22
SRA x1, x3, x2
SLTI x2, x0, 39
SRL x3, x4, x3
SLLI x3, x1, 18
LUI x0, 23
SRAI x4, x4, 31
SRAI x2, x3, 25
SLTU x2, x0, x3
ORI x2, x0, -19
SLTI x3, x1, -21
SRAI x0, x3, 18
AND x3, x0, x3
SRL x3, x2, x2
ANDI x2, x0, 76
AND x2, x3, x2
ADD x2, x4, x3
LB x2, 16(x7)
ORI x1, x3, -13
LHU x2, 12(x7)
SLLI x2, x4, 7
ORI x2, x0, 91
ADDI x3, x1, -90
SRA x4, x1, x0
OR x3, x3, x1
ORI x0, x1, 65
SLL x0, x2, x0
LUI x4, 1
LH x0, 0(x7)
XOR x2, x4, x4
SLT x4, x2, x3
SLTI x1, x3, -18
SRA x3, x3, x2
ADDI x0, x3, -12
SRL x1, x4, x2
LB x1, 0(x7)
ADD x0, x4, x2
LH x3, 4(x7)
SUB x4, x0, x2
LB x1, 20(x7)
SLT x3, x1, x3
LH x1, 20(x7)
LHU x4, 16(x7)
AUIPC x2, 9
AND x3, x1, x2
SUB x2, x0, x1
SRAI x0, x0, 24
SLLI x2, x2, 26
ADDI x0, x2, 56
OR x0, x4, x0
ANDI x4, x4, -37
SLT x1, x4, x2
SUB x4, x3, x4
LUI x3, 2
SRL x3, x2, x4
LUI x0, 8
SLLI x1, x0, 13
SRAI x1, x3, 20
SRA x2, x3, x0
SLTI x4, x0, -68
SRL x4, x0, x4
OR x4, x0, x4
OR x4, x2, x0
SUB x0, x4, x4
ADDI x4, x2, 58
LBU x2, 8(x7)
AND x1, x2, x1
LB x2, 0(x7)
SUB x4, x4, x2
LB x4, 16(x7)
ADDI x2, x3, 58
SLL x1, x3, x0
LB x0, 4(x7)
SLL x0, x1, x3
LUI x0, 27
ANDI x4, x3, -69
XOR x4, x2, x1
AND x4, x3, x1
ADDI x4, x4, 75
SRA x0, x2, x1
LB x4, 12(x7)
SLT x0, x1, x4
ORI x0, x2, 17
XORI x0, x4, 49
ORI x4, x0, -18
AND x1, x1, x3
XOR x4, x3, x0
SLLI x1, x0, 16
SLL x3, x4, x0
SUB x3, x2, x1
AUIPC x0, 8
LB x1, 16(x7)
LHU x4, 20(x7)
AUIPC x0, 3
XORI x4, x1, -46
AUIPC x4, 4
LB x2, 16(x7)
SLLI x1, x0, 7
SLT x0, x0, x2
XORI x2, x1, -52
AND x3, x3, x4
SRAI x2, x1, 20
SLTU x1, x0, x1
LUI x2, 7
LUI x2, 12
SRA x1, x2, x2
SLTIU x1, x4, 44
LHU x0, 20(x7)
OR x4, x1, x0
ADDI x4, x4, 71
LB x0, 20(x7)
LBU x2, 16(x7)
OR x0, x2, x2
SLTI x1, x2, 90
SLTI x4, x0, -99
LB x3, 4(x7)
LUI x2, 28
ADD x0, x0, x0
SRA x2, x2, x2
XOR x4, x2, x0
SLL x1, x1, x2
ADDI x3, x0, -67
ADDI x4, x3, 10
AUIPC x4, 0
ANDI x1, x3, 55
LB x2, 20(x7)
XOR x3, x3, x1
LUI x0, 14
XOR x4, x4, x3
SUB x0, x2, x1
SUB x3, x1, x0
SLTIU x4, x2, -32
SLT x3, x2, x1
AND x3, x2, x1
ORI x2, x3, 70
ADDI x4, x4, 43
LH x2, 0(x7)
SUB x1, x4, x1
SUB x4, x3, x2
SUB x3, x3, x3
OR x3, x3, x1
SLTIU x1, x3, -41
AND x2, x4, x0
ANDI x2, x4, -53
XORI x0, x1, -99
XOR x1, x3, x4
LH x1, 20(x7)
LHU x3, 20(x7)
SLL x2, x3, x2
SRA x4, x4, x1
AND x2, x4, x0
SLTU x1, x1, x4
XORI x0, x0, 97
ADDI x1, x3, 16
LH x1, 12(x7)
LB x0, 4(x7)
SRAI x1, x3, 2
XORI x4, x4, -56
SRL x1, x0, x1
SLTI x2, x3, 24
XORI x3, x1, -58
SLTU x0, x3, x4
SUB x2, x3, x3
XORI x1, x3, -51
SLTIU x4, x1, -38
LUI x0, 8
LH x1, 0(x7)
LUI x3, 21
SLTU x4, x3, x1
SLTU x3, x3, x4
LB x0, 4(x7)
SLTIU x2, x1, -74
SLTU x1, x2, x2
SLTIU x0, x1, -74
XORI x4, x2, 68
AUIPC x3, 14
LHU x2, 4(x7)
SLTU x1, x3, x0
ANDI x4, x3, 43
LH x3, 12(x7)
LB x3, 12(x7)
XOR x0, x2, x4
SLT x2, x1, x0
LHU x4, 0(x7)
SRA x1, x3, x1
SLL x3, x0, x0
SLLI x3, x0, 14
ADDI x3, x4, 29
AUIPC x0, 2
SRA x1, x2, x3
XOR x1, x1, x2
SRLI x1, x1, 31
SLTIU x3, x1, -45
ADD x4, x3, x4
LBU x0, 12(x7)
AUIPC x0, 20
SRAI x3, x3, 12
SLTIU x4, x4, 74
AND x4, x4, x1
LHU x3, 12(x7)
SLTU x2, x4, x0
SRA x2, x3, x3
SRAI x4, x3, 16
AUIPC x2, 15
SLLI x4, x3, 3
SRLI x4, x4, 26
XORI x1, x3, -1
ORI x4, x4, 11
LHU x3, 8(x7)
LH x3, 4(x7)
AND x3, x4, x0
SLTU x1, x0, x0
SRA x4, x0, x3
SLTIU x0, x2, 2
SLTI x3, x4, -5
SRA x2, x2, x0
ORI x3, x3, -28
LUI x3, 30
SRLI x1, x4, 22
SLTI x0, x4, 25
SLTU x3, x3, x4
SUB x3, x2, x1
SRA x3, x1, x3
SLTI x1, x2, 55
ORI x1, x4, -2
ORI x3, x2, 19
AND x3, x0, x4
SRA x3, x0, x2
SUB x0, x3, x1
SLT x3, x1, x1
SLLI x2, x1, 1
OR x2, x4, x2
LB x0, 8(x7)
XOR x4, x4, x1
SRAI x0, x2, 12
SRAI x3, x0, 12
ANDI x0, x4, -20
LUI x1, 5
OR x2, x2, x3
AND x4, x4, x1
LB x2, 12(x7)
AUIPC x1, 28
SRL x3, x4, x2
SLTIU x1, x0, 50
ANDI x4, x1, -42
AUIPC x1, 14
XOR x0, x0, x3
XORI x0, x0, -30
LB x1, 8(x7)
SLTI x2, x1, -23
AND x0, x2, x4
XORI x1, x4, 55
ORI x1, x2, -65
LUI x3, 2
SRL x2, x2, x1
LH x1, 12(x7)
LBU x4, 4(x7)
LBU x3, 0(x7)
OR x2, x0, x4
ADDI x0, x2, -62
SLTU x2, x1, x2
AND x1, x1, x2
AND x3, x4, x0
LBU x2, 12(x7)
ORI x3, x3, 64
SLTIU x4, x0, -88
SLTI x1, x0, -2
XOR x0, x0, x1
OR x1, x4, x1
ORI x2, x4, 98
SLTI x1, x0, -13
LB x4, 8(x7)
XOR x4, x4, x4
SLTIU x0, x0, -54
ADD x3, x3, x0
ADD x4, x3, x0
LBU x1, 8(x7)
LH x1, 0(x7)
SRL x3, x3, x2
SRA x1, x3, x1
XORI x4, x3, -23
ORI x1, x4, -35
SLTI x4, x4, 45
SLTU x0, x3, x3
LHU x4, 8(x7)
SRAI x0, x0, 26
ORI x0, x3, -95
SRAI x2, x2, 5
SRLI x0, x3, 17
LB x4, 0(x7)
SRA x0, x4, x3
LHU x4, 8(x7)
SLT x4, x3, x4
ADD x1, x4, x1
ANDI x2, x3, 56
SRAI x3, x0, 28
SLTI x2, x2, -73
SRLI x0, x4, 1
SLL x2, x4, x3
SRA x3, x4, x3
SLT x1, x2, x1
SUB x4, x0, x4
ADD x1, x0, x2
ADD x0, x0, x3
SLTI x4, x3, -87
SRL x2, x1, x2
LHU x4, 0(x7)
SRAI x3, x0, 28
LHU x0, 4(x7)
AUIPC x4, 20
SRA x4, x0, x1
LH x0, 20(x7)
LH x0, 0(x7)
ADDI x2, x4, 80
ADDI x3, x0, 93
SUB x1, x1, x2
XOR x3, x4, x0
LUI x2, 29
AUIPC x4, 5
ANDI x1, x4, 51
SLTU x4, x2, x2
SLT x0, x3, x2
AND x1, x3, x4
SLT x1, x2, x0
XORI x3, x4, -16
ORI x2, x1, 39
LH x0, 8(x7)
SUB x2, x1, x0
SRLI x2, x3, 28
SRA x2, x3, x2
SRL x1, x0, x4
XOR x2, x3, x1
SLTU x3, x1, x2
XORI x3, x2, -99
SRA x4, x2, x4
XOR x2, x1, x0
SRAI x1, x3, 3
LH x4, 16(x7)
LB x3, 16(x7)
AUIPC x1, 11
ADDI x3, x0, 16
XORI x3, x2, 6
SLT x1, x4, x4
ADD x3, x0, x2
ADDI x3, x0, -8
SLTIU x0, x2, -8
AUIPC x1, 11
SLLI x0, x2, 20
ORI x3, x0, 54
OR x4, x0, x2
LHU x3, 0(x7)
SLT x3, x4, x1
SLT x0, x2, x2
SUB x3, x0, x1
OR x2, x3, x0
ADD x1, x3, x0
ADD x1, x0, x0
ADD x0, x0, x0
OR x0, x2, x4
LB x3, 16(x7)
SLTI x4, x1, 20
SRL x2, x4, x0
ORI x3, x1, -66
SUB x2, x3, x1
LBU x0, 12(x7)
SLTIU x0, x0, -6
LUI x0, 14
SRA x4, x4, x3
ADDI x3, x4, 90
LUI x3, 27
ADD x4, x1, x0
SLL x4, x0, x1
SRA x4, x4, x4
ORI x1, x2, 76
SRLI x3, x1, 23
ORI x3, x3, 31
LBU x1, 16(x7)
SLTU x2, x0, x4
ADDI x2, x3, -59
SLTU x0, x4, x4
SRA x1, x0, x1
SRL x3, x2, x3
SLT x3, x2, x4
SRAI x4, x3, 20
SLLI x4, x1, 8
LUI x4, 27
SRLI x0, x3, 13
LB x2, 0(x7)
AND x4, x1, x4
XORI x2, x0, -49
ORI x4, x2, 24
ANDI x1, x4, -35
XORI x3, x1, 38
ORI x1, x1, 89
ADDI x2, x3, 14
OR x3, x4, x2
LBU x2, 12(x7)
AND x4, x1, x4
ANDI x2, x2, -23
LBU x1, 20(x7)
ORI x2, x2, -88
SLLI x4, x2, 31
AND x0, x3, x4
SLLI x2, x3, 28
SLTIU x4, x0, 15
AND x3, x1, x1
LBU x2, 0(x7)
ORI x4, x1, -60
SRAI x0, x4, 1
LH x1, 12(x7)
SLTI x0, x2, 72
ORI x2, x2, 31
XORI x4, x1, -37
SRLI x4, x2, 15
OR x4, x3, x3
SRL x0, x1, x2
SUB x1, x2, x3
SLLI x0, x1, 22
OR x3, x1, x0
OR x3, x3, x2
XORI x2, x1, -9
SLTI x1, x0, -4
AUIPC x2, 11
SLTU x1, x4, x3
LH x3, 20(x7)
SRLI x1, x2, 3
SRA x4, x2, x2
ANDI x4, x1, -45
LBU x1, 20(x7)
ANDI x2, x4, 46
LH x3, 4(x7)
ADD x2, x3, x1
SLTIU x3, x2, 83
SLTU x3, x0, x0
LBU x1, 20(x7)
ADD x2, x0, x2
ADD x0, x0, x2
LBU x1, 16(x7)
SLTIU x3, x4, -90
LUI x4, 24
LBU x0, 4(x7)
SLT x0, x2, x0
LH x1, 20(x7)
LBU x3, 20(x7)
OR x2, x1, x3
SRLI x3, x3, 21
ADD x1, x3, x2
LBU x3, 16(x7)
ADD x4, x2, x2
LHU x2, 20(x7)
SLT x1, x0, x4
ADD x2, x4, x4
LB x1, 0(x7)
ADD x3, x4, x0
XORI x0, x4, -69
LH x3, 8(x7)
OR x4, x1, x2
SRL x0, x0, x2
OR x0, x0, x1
SLT x1, x4, x0
ADD x0, x4, x2
XOR x1, x1, x1
SUB x1, x3, x4
SRA x3, x1, x1
XOR x4, x0, x2
LH x1, 4(x7)
SLT x0, x1, x3
SRA x2, x1, x3
ADD x0, x3, x1
SRA x3, x1, x3
SLL x1, x2, x0
LHU x3, 8(x7)
ANDI x2, x2, -8
XORI x2, x2, 26
LBU x2, 0(x7)
SLTI x0, x0, -14
SRAI x0, x3, 19
SRLI x2, x0, 3
SLTI x0, x3, -79
SRAI x3, x1, 16
ADDI x0, x1, 33
SLTI x3, x4, -36
LH x0, 20(x7)
LUI x4, 1
SRLI x4, x3, 23
LB x4, 8(x7)
SRL x0, x3, x3
SRA x0, x3, x4
SLTU x2, x2, x1
ADD x4, x0, x3
ADD x4, x4, x0
SLL x1, x4, x0
AND x2, x4, x0
LUI x4, 25
AND x0, x1, x4
SRA x4, x1, x2
ANDI x3, x4, 31
ANDI x1, x1, 24
ADDI x3, x3, -14
SRLI x4, x0, 3
SLLI x1, x3, 27
LUI x3, 15
OR x4, x2, x3
XORI x1, x1, -36
LH x1, 20(x7)
XOR x4, x1, x0
AUIPC x1, 15
OR x2, x0, x1
ORI x0, x2, -36
SLL x3, x2, x3
LUI x3, 14
ORI x3, x3, -91
SRLI x1, x1, 30
ADDI x0, x1, -18
SLTU x4, x1, x3
SLT x0, x0, x1
SRL x1, x3, x1
SLTI x0, x4, -31
ADDI x3, x2, 16
XORI x0, x2, 20
LH x0, 16(x7)
SLTI x2, x4, 18
XORI x2, x1, 97
SRLI x3, x4, 0
SRA x4, x4, x3
LHU x4, 8(x7)
SLTI x4, x0, -48
SLTIU x4, x2, -22
LB x1, 0(x7)
AND x1, x0, x1
ANDI x0, x0, 79
SLLI x1, x3, 27
ADDI x0, x1, -6
AND x1, x4, x4
LB x4, 0(x7)
SLTI x2, x1, 47
SLT x2, x4, x0
SLL x4, x4, x3
SRAI x2, x3, 26
SRA x4, x2, x4
LHU x3, 8(x7)
AUIPC x2, 4
LB x0, 4(x7)
SLTU x0, x2, x4
LBU x4, 0(x7)
XORI x4, x0, -74
ORI x4, x1, 99
LHU x4, 0(x7)
SLTIU x1, x4, -14
SLL x1, x1, x0
SLLI x3, x3, 30
LHU x2, 8(x7)
OR x3, x0, x0
LH x0, 8(x7)
ADD x4, x0, x2
ORI x2, x4, -7
AUIPC x3, 0
ADD x2, x1, x1
LUI x2, 2
AND x4, x3, x0
SRA x3, x1, x2
ORI x1, x0, -78
SUB x1, x0, x3
SRL x0, x2, x3
SLTU x3, x2, x0
SLTI x0, x4, 87
SRAI x0, x0, 10
SRA x4, x4, x0
LH x0, 0(x7)
SLTI x3, x3, -78
SLT x1, x0, x0
SUB x4, x4, x4
LB x3, 20(x7)
SRA x0, x4, x3
LUI x4, 14
SLT x4, x1, x1
AUIPC x0, 2
AND x1, x3, x2
LH x1, 4(x7)
SLLI x2, x4, 3
SLTIU x2, x1, -99
LUI x2, 19
AUIPC x0, 15
SLTU x3, x3, x1
SLL x4, x4, x3
XOR x1, x0, x2
XOR x0, x0, x3
SLT x3, x0, x2
SUB x0, x3, x1
SLLI x4, x1, 29
SLTIU x1, x0, 27
XOR x0, x2, x1
SRAI x1, x4, 15
ADD x0, x4, x4
SLT x3, x0, x1
AND x4, x4, x1
XOR x2, x3, x1
SLTIU x4, x0, -15
SUB x4, x0, x0
SUB x4, x2, x4
SLT x1, x2, x3
SLTU x3, x3, x1
AUIPC x4, 31
SRLI x3, x3, 8
SRA x3, x0, x4
ADDI x2, x2, 46
SRAI x0, x4, 21
SLTIU x1, x3, -87
LUI x2, 13
SRLI x1, x1, 27
AUIPC x4, 8
LBU x4, 16(x7)
XOR x4, x0, x3
AUIPC x4, 9
LHU x2, 16(x7)
LH x2, 4(x7)
ANDI x3, x2, -10
SLTIU x2, x3, 27
XORI x4, x4, 44
XORI x3, x1, -28
LUI x1, 22
ANDI x2, x2, 60
SLT x1, x0, x1
SLL x0, x2, x2
LH x4, 12(x7)
XOR x1, x1, x0
SRL x4, x3, x2
LBU x4, 12(x7)
SRLI x3, x3, 29
OR x0, x0, x4
XOR x4, x3, x3
SLTIU x4, x0, -14
SLTU x0, x3, x2
OR x0, x3, x2
OR x2, x2, x3
SLTU x4, x2, x2
SLL x4, x1, x2
SUB x4, x3, x0
LB x4, 4(x7)
SUB x2, x1, x1
SRAI x3, x0, 0
SLTIU x2, x3, 93
SLL x1, x0, x1
SRLI x1, x1, 1
LB x1, 8(x7)
AND x3, x0, x3
XORI x3, x2, -12
LB x3, 16(x7)
ADD x4, x0, x2
LHU x0, 16(x7)
LB x4, 12(x7)
LHU x0, 16(x7)
ADDI x3, x4, -7
LBU x4, 4(x7)
LHU x4, 12(x7)
ANDI x0, x4, -69
ADD x3, x1, x1
SRL x3, x2, x1
LUI x4, 17
AUIPC x4, 22
ADDI x0, x4, -96
SLT x4, x0, x3
LUI x3, 11
SLTU x3, x0, x3
XOR x4, x3, x1
SRL x4, x1, x3
AUIPC x1, 5
LUI x3, 7
SLTU x3, x3, x3
LHU x1, 16(x7)
SRLI x2, x2, 19
OR x0, x0, x0
XOR x1, x3, x1
LHU x1, 12(x7)
SRLI x3, x2, 10
SRLI x0, x0, 29
SLTU x1, x3, x2
LHU x1, 0(x7)
LHU x0, 16(x7)
ADDI x1, x3, 98
LB x1, 4(x7)
SRL x4, x2, x2
LUI x0, 21
SLTI x4, x4, -75
SLT x1, x0, x4
XORI x1, x2, 62
SLTU x4, x0, x0
AND x1, x3, x3
SLT x0, x0, x0
SUB x4, x2, x0
SRA x2, x0, x1
LH x3, 8(x7)
AND x2, x3, x2
AND x1, x0, x2
AND x1, x3, x4
SLTU x1, x0, x3
XOR x0, x1, x2
SLL x3, x2, x0
LUI x4, 17
LUI x1, 25
ADDI x4, x2, 13
ADD x2, x2, x2
ANDI x4, x0, 58
LH x0, 20(x7)
LHU x0, 8(x7)
LHU x0, 12(x7)
AND x1, x4, x2
AND x1, x2, x1
SRLI x2, x1, 20
SRA x3, x4, x4
OR x4, x2, x0
SRA x3, x4, x4
ADD x0, x2, x0
LH x4, 4(x7)
SLLI x4, x1, 28
AUIPC x0, 3
LB x3, 20(x7)
SRAI x4, x1, 2
OR x2, x0, x2
ORI x0, x4, 7
LH x1, 8(x7)
SRLI x4, x2, 6
SRLI x2, x4, 11
LH x2, 20(x7)
LH x2, 4(x7)
ADD x1, x4, x3
XORI x2, x3, 33
ADD x3, x2, x2
LB x2, 8(x7)
SUB x3, x4, x4
AUIPC x1, 17
ORI x2, x0, -83
SLTU x4, x3, x1
LH x4, 8(x7)
SLTI x3, x2, -54
ADDI x3, x4, -82
SLT x0, x3, x0
SRAI x4, x0, 23
LBU x4, 4(x7)
LB x1, 4(x7)
LHU x4, 4(x7)
SUB x3, x1, x0
OR x1, x4, x3
SRA x2, x4, x4
SLTI x2, x2, -49
XOR x3, x3, x3
SRLI x4, x1, 3
LH x3, 16(x7)
SRLI x3, x4, 7
ANDI x4, x3, -53
ORI x1, x3, 35
ANDI x4, x4, 89
AND x0, x4, x1
SLLI x1, x2, 6
SLTIU x3, x3, -40
ADDI x2, x0, 29
SLTIU x2, x0, 87
LHU x1, 12(x7)
ORI x2, x4, 67
SRL x2, x0, x0
SLLI x0, x0, 15
ANDI x2, x3, -58
SRLI x1, x0, 15
LBU x0, 8(x7)
XOR x1, x2, x1
LB x1, 4(x7)
ORI x1, x2, 34
ORI x4, x3, 76
SRLI x1, x4, 14
SLTU x4, x0, x4
SLTIU x1, x4, 33
SRAI x2, x2, 4
SRL x3, x2, x1
SRLI x1, x4, 0
AND x3, x4, x2
AUIPC x1, 5
SLT x1, x3, x4
ANDI x2, x4, -68
LH x1, 20(x7)
LBU x1, 8(x7)
ADDI x3, x4, 83
ADD x2, x0, x0
SLL x3, x3, x2
ADD x0, x0, x1
SRL x0, x0, x4
SRLI x1, x2, 27
XORI x0, x1, 100
SRAI x3, x1, 10
LUI x4, 16
SLL x3, x0, x2
AUIPC x3, 30
SLT x2, x4, x2
SRAI x2, x3, 20
SLL x2, x3, x4
SRA x2, x1, x0
SLL x3, x1, x3
SRL x1, x0, x2
AND x4, x1, x2
SLTIU x2, x2, -27
XOR x2, x1, x4
ANDI x1, x2, 2
AND x2, x0, x4
SRA x2, x3, x3
SLLI x4, x4, 19
LB x2, 20(x7)
SLTIU x1, x3, -89
XOR x1, x1, x3
LH x1, 12(x7)
SLLI x4, x1, 4
SLT x3, x2, x0
SRL x4, x3, x3
SLTU x1, x0, x1
LUI x2, 20
SLL x4, x2, x3
SLTI x2, x4, 50
SRLI x1, x0, 18
AND x0, x2, x1
ADDI x4, x1, -6
ADD x3, x2, x4
SLTIU x2, x4, 24
LBU x1, 8(x7)
ANDI x3, x2, -21
LHU x1, 8(x7)
LH x2, 12(x7)
XORI x4, x3, 52
LB x1, 4(x7)
ADDI x4, x1, -25
ANDI x4, x4, 74
SLTIU x2, x1, -45
SRAI x2, x0, 5
SLTU x1, x3, x0
ADD x4, x3, x3
SLT x3, x4, x4
SLLI x3, x3, 0
ORI x4, x3, 12
AND x0, x4, x0
SRL x4, x4, x3
SRA x2, x2, x4
LUI x1, 4
ADD x1, x1, x1
LBU x4, 16(x7)
SLL x1, x2, x1
XOR x0, x4, x0
SRA x4, x4, x2
AND x1, x0, x0
SRLI x3, x0, 10
SLL x0, x3, x0
ANDI x3, x1, 42
LB x2, 0(x7)
ADD x4, x0, x0
SLTI x3, x0, -19
ORI x4, x4, 16
SRA x4, x4, x4
LH x0, 12(x7)
LH x4, 0(x7)
SUB x2, x4, x1
OR x0, x2, x2
LHU x3, 16(x7)
SRL x4, x3, x3
ORI x0, x0, -67
LHU x4, 12(x7)
OR x2, x3, x0
ANDI x4, x2, 25
AND x4, x2, x0
SLLI x4, x4, 0
SLTI x4, x0, 12
LBU x2, 4(x7)
XOR x4, x4, x3
SRL x3, x1, x2
SRLI x2, x0, 4
ANDI x2, x3, 89
ANDI x1, x2, 83
OR x1, x1, x1
SRAI x0, x0, 20
LUI x1, 12
SLTIU x1, x2, 91
ANDI x0, x1, 67
SLTI x2, x1, 15
SRAI x4, x3, 20
SUB x2, x2, x2
SUB x2, x2, x0
SUB x4, x0, x4
LHU x0, 8(x7)
SRLI x1, x0, 13
SLL x2, x3, x1
SRL x3, x3, x2
SLTU x3, x1, x0
SLL x2, x4, x4
SRL x4, x3, x3
LB x1, 4(x7)
ORI x1, x4, -25
LH x2, 4(x7)
SRAI x1, x0, 4
AUIPC x3, 4
LBU x1, 20(x7)
SRL x3, x1, x0
ORI x4, x0, 62
SRA x2, x1, x3
ADD x2, x1, x0
LHU x3, 12(x7)
SLTU x0, x1, x3
SUB x1, x3, x3
LHU x1, 20(x7)
ORI x1, x1, 26
ANDI x3, x4, -8
SLTI x0, x3, -65
LB x0, 4(x7)
ADDI x1, x2, -57
SRL x1, x4, x4
ANDI x1, x1, -5
AUIPC x0, 22
OR x3, x3, x4
SLTI x2, x4, 44
LH x2, 8(x7)
ADD x1, x4, x1
AND x1, x3, x1
SRA x2, x4, x3
LUI x2, 27
SRAI x3, x2, 16
SLL x2, x4, x2
LUI x1, 10
SRA x4, x4, x2
XORI x2, x3, 86
SLTIU x1, x3, -7
SRA x4, x3, x3
AUIPC x2, 20
XORI x1, x3, -78
ANDI x3, x3, -72
SLTI x4, x2, 89
SUB x0, x3, x1
ANDI x4, x3, 17
SUB x0, x4, x0
SRLI x2, x3, 11
ORI x2, x2, 73
SRLI x4, x3, 2
LHU x4, 8(x7)
OR x1, x1, x3
SLL x1, x2, x1
LH x0, 0(x7)
LBU x1, 8(x7)
ANDI x2, x3, -32
LB x1, 8(x7)
SRL x2, x4, x4
ADDI x3, x2, 11
ANDI x3, x4, 49
LBU x3, 20(x7)
ADDI x2, x0, 35
SRLI x3, x1, 20
ADD x3, x2, x0
AND x0, x3, x2
SLLI x2, x1, 6
SRLI x3, x3, 22
SLTIU x4, x4, -2
SLL x4, x1, x4
LH x1, 8(x7)
SRLI x2, x1, 8
ADDI x4, x1, -70
SRAI x3, x0, 3
ANDI x1, x3, 37
AUIPC x4, 7
AUIPC x2, 21
AND x4, x2, x2
SRA x3, x2, x3
LUI x0, 31
AND x1, x0, x0
SLL x4, x0, x4
SRL x2, x3, x3
OR x4, x4, x1
ORI x4, x1, 87
OR x1, x1, x4
LH x4, 16(x7)
ADDI x4, x4, -48
LH x2, 16(x7)
SLL x2, x3, x3
AUIPC x3, 18
SRAI x0, x1, 5
SRAI x2, x0, 8
SRA x1, x0, x3
SUB x2, x0, x4
SLLI x4, x1, 0
ADDI x4, x3, 13
SLLI x2, x2, 31
AUIPC x3, 19
SUB x4, x0, x0
SLLI x2, x4, 22
SLTI x3, x0, 38
XORI x1, x0, 17
ORI x4, x4, 61
SRL x4, x2, x1
ADD x2, x1, x3
XOR x1, x3, x3
XORI x4, x4, -45
XOR x2, x3, x2
ADD x3, x3, x2
OR x1, x3, x1
LB x4, 12(x7)
LH x2, 16(x7)
SLTIU x1, x4, -62
SLTU x2, x2, x3
SRA x0, x3, x4
SRA x3, x3, x1
ADDI x3, x2, 0
SLL x1, x1, x1
LBU x0, 16(x7)
AND x4, x1, x4
SRA x3, x3, x1
SLT x2, x0, x2
ORI x1, x0, -64
SRAI x4, x4, 7
ANDI x1, x0, 91
SLTU x4, x4, x0
XOR x1, x1, x2
LH x4, 8(x7)
SLL x2, x0, x3
ORI x0, x0, 70
ADD x2, x3, x0
SLTIU x2, x4, 43
SLTI x4, x1, 0
ANDI x1, x2, 16
LB x2, 20(x7)
XOR x2, x3, x2
SRA x0, x1, x2
SRA x0, x4, x0
LBU x1, 8(x7)
LB x1, 8(x7)
SUB x3, x2, x2
SLT x0, x2, x1
SLL x2, x2, x4
LH x0, 20(x7)
SLLI x1, x3, 11
AUIPC x3, 24
LBU x3, 12(x7)
SLTIU x4, x4, -14
LUI x0, 30
SLTU x2, x2, x0
ADD x3, x0, x4
ADD x1, x2, x3
XORI x0, x3, -79
ANDI x0, x2, -11
AND x1, x4, x2
SRLI x3, x3, 20
SRLI x2, x3, 21
AUIPC x0, 0
SRAI x0, x3, 31
XORI x3, x1, -53
LH x1, 0(x7)
OR x4, x1, x4
SUB x0, x4, x0
OR x0, x4, x2
LH x3, 0(x7)
SLT x4, x4, x0
AND x1, x0, x1
SLLI x0, x0, 27
ADD x1, x2, x3
SRA x0, x3, x0
SLT x3, x4, x0
AUIPC x3, 22
SLT x2, x1, x1
OR x3, x0, x2
LH x3, 0(x7)
SLTIU x4, x1, -80
SLTIU x1, x3, -95
SRL x1, x1, x4
SLT x3, x1, x2
ANDI x2, x4, -63
AND x1, x1, x4
ANDI x3, x0, 21
XORI x2, x4, 11
SRL x3, x3, x4
SLTI x1, x3, -56
LHU x3, 12(x7)
SLLI x4, x4, 6
SLTU x4, x4, x0
SLL x1, x4, x4
XOR x3, x4, x1
LHU x1, 0(x7)
ORI x0, x0, -13
LHU x2, 20(x7)
LB x3, 12(x7)
SRA x2, x4, x0
SRAI x0, x4, 19
SLLI x4, x1, 23
ADDI x2, x4, 28
LBU x1, 16(x7)
AUIPC x2, 19
SLTI x0, x2, -94
LBU x3, 12(x7)
OR x1, x3, x2
LHU x3, 16(x7)
SRL x2, x4, x1
LB x3, 20(x7)
LH x0, 4(x7)
SRLI x1, x1, 30
LBU x3, 12(x7)
ANDI x0, x1, -67
LUI x4, 26
SLTU x1, x3, x0
SLL x1, x2, x1
SLT x4, x2, x4
XORI x2, x0, 59
SLTI x3, x1, 79
SRL x3, x1, x3
SLTIU x2, x2, 58
SRL x2, x3, x1
XORI x3, x2, -52
ORI x2, x2, -51
ANDI x2, x3, 95
SLTU x2, x2, x3
SLLI x3, x1, 14
AND x1, x3, x1
ADDI x1, x2, 94
SRAI x3, x3, 24
AND x0, x2, x1
OR x2, x1, x1
OR x2, x2, x0
LHU x0, 12(x7)
SRAI x2, x1, 5
SLTI x4, x2, -99
AND x2, x4, x2
SLTIU x3, x4, 94
SLTI x1, x1, -36
SLLI x0, x2, 16
SLL x2, x2, x0
ADDI x4, x4, 95
AUIPC x1, 20
SLL x1, x0, x3
SRL x2, x0, x2
ADD x0, x3, x4
SRA x1, x4, x0
LHU x4, 16(x7)
AND x1, x4, x1
XORI x1, x4, -16
SLT x2, x4, x3
SLTIU x3, x0, 39
SRA x1, x3, x3
LB x4, 0(x7)
ADDI x2, x4, -90
LUI x3, 17
LH x2, 0(x7)
SUB x2, x1, x0
LH x4, 16(x7)
OR x3, x2, x2
XORI x4, x4, 25
SLL x3, x0, x1
SLTIU x0, x2, -27
LH x3, 12(x7)
ANDI x0, x0, -95
SLTIU x2, x1, 88
ADD x3, x4, x2
LUI x1, 21
LHU x3, 16(x7)
OR x4, x3, x1
ADD x0, x3, x0
SLTIU x0, x2, -16
SRLI x1, x4, 25
SLLI x3, x1, 21
OR x3, x2, x2
ADD x2, x2, x1
SLTIU x0, x2, 59
SLTIU x0, x4, 30
SRL x1, x2, x4
LUI x3, 4
SLT x3, x0, x4
SRLI x2, x3, 17
ADD x2, x0, x0
SRA x0, x0, x4
XOR x4, x4, x4
ORI x4, x2, -27
ADD x2, x2, x0
LB x0, 16(x7)
SRA x1, x1, x2
SRLI x4, x4, 8
ADDI x4, x1, 94
OR x1, x3, x2
SLTI x1, x2, 8
SLT x2, x4, x3
SLT x0, x4, x4
ANDI x3, x2, 57
SRAI x0, x2, 31
LH x1, 8(x7)
OR x3, x1, x1
SLL x2, x1, x1
ANDI x1, x2, -26
ORI x2, x0, -26
SLT x2, x0, x3
SUB x2, x2, x4
ORI x0, x4, -1
SRAI x3, x2, 19
ANDI x4, x1, -27
LHU x1, 20(x7)
LHU x1, 4(x7)
SLTIU x0, x3, -60
ANDI x0, x3, -98
XOR x1, x3, x1
OR x1, x3, x0
LBU x2, 20(x7)
OR x0, x4, x2
LHU x2, 12(x7)
LH x0, 20(x7)
ORI x3, x4, 72
SLT x3, x1, x2
ANDI x2, x4, -76
ORI x3, x3, -68
SLTIU x3, x3, -16
ANDI x2, x0, 14
SUB x4, x3, x0
ANDI x3, x0, 55
SRA x4, x0, x2
ADD x0, x2, x2
SLTI x3, x4, -6
SRA x2, x1, x0
SUB x0, x4, x3
SLTI x0, x3, -81
SUB x4, x4, x1
OR x2, x3, x4
AND x0, x1, x4
LHU x3, 0(x7)
SRL x4, x2, x1
SLT x0, x4, x4
SLL x0, x0, x4
AUIPC x2, 17
AND x0, x0, x4
LH x1, 20(x7)
SRAI x3, x2, 3
SLLI x4, x1, 11
SRLI x0, x2, 8
XORI x1, x4, -79
AND x2, x0, x1
SLTU x0, x2, x3
SRA x0, x4, x1
LB x1, 20(x7)
AUIPC x0, 20
SLLI x2, x4, 5
SRLI x3, x3, 21
SUB x3, x0, x3
LUI x2, 2
SLTI x3, x1, -17
SRL x3, x0, x0
SRL x1, x1, x0
ADD x3, x3, x1
LHU x2, 16(x7)
SRAI x0, x1, 30
SRL x2, x0, x3
SLL x0, x0, x4
SLL x0, x2, x4
SLTI x2, x4, -63
SRL x1, x1, x3
LH x4, 20(x7)
SRLI x2, x1, 7
SRLI x3, x2, 1
AUIPC x1, 2
SLL x0, x1, x3
SLTIU x3, x4, -1
SRA x1, x2, x4
ADD x4, x3, x0
SLT x4, x2, x0
LB x1, 12(x7)
LUI x0, 21
LUI x2, 9
SRAI x4, x3, 6
ANDI x0, x4, 61
SLT x4, x2, x2
SLTI x3, x0, 91
LUI x3, 25
ADD x3, x0, x3
AUIPC x4, 14
XORI x4, x4, 72
LHU x3, 12(x7)
LB x2, 16(x7)
ORI x4, x2, 100
XOR x2, x3, x4
XORI x4, x3, 100
SLTI x1, x1, -90
OR x4, x4, x3
AND x1, x2, x0
AUIPC x1, 25
SLTIU x3, x1, 14
ADD x2, x1, x4
AND x2, x1, x1
ADDI x4, x2, 14
XOR x2, x3, x4
AUIPC x2, 9
LH x0, 4(x7)
AUIPC x1, 0
SRLI x2, x4, 19
SLLI x4, x0, 3
SLTI x1, x2, 52
AUIPC x0, 10
SLLI x4, x0, 21
SUB x0, x3, x2
SRA x2, x0, x3
AND x4, x3, x1
ANDI x2, x2, 57
SRLI x2, x1, 16
ADDI x3, x3, 43
ANDI x0, x3, -8
OR x2, x2, x2
SLTI x4, x0, -1
XORI x3, x2, 76
LH x1, 0(x7)
XOR x3, x1, x4
SLL x3, x2, x4
SLTIU x1, x4, 85
SRLI x3, x0, 15
OR x3, x3, x1
SLT x1, x4, x1
LB x1, 8(x7)
SLT x2, x4, x3
ORI x4, x3, 86
ANDI x0, x3, 7
SLTIU x2, x1, 73
AUIPC x3, 5
ORI x0, x3, -59
LUI x1, 8
SRAI x1, x1, 26
AND x1, x2, x3
SLTU x0, x0, x4
LB x2, 8(x7)
SLL x1, x3, x2
ADD x4, x1, x4
ORI x0, x2, -32

slti x0, x0, -256 # this is the magic instruction to end the simulation