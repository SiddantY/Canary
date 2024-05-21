/////////////////////////////////////////////////////////////
//  Maybe use some of your types from mp_pipeline here?    //
//    Note you may not need to use your stage structs      //
/////////////////////////////////////////////////////////////
// localparam SETS = 16;
package rv32i_types;

    // opcode definitions

    typedef enum logic [6:0] {
        op_b_lui   = 7'b0110111, // U load upper immediate 
        op_b_auipc = 7'b0010111, // U add upper immediate PC 
        op_b_jal   = 7'b1101111, // J jump and link 
        op_b_jalr  = 7'b1100111, // jump and link register (I type)
        op_b_br    = 7'b1100011, // B branch 
        op_b_load  = 7'b0000011, // I load 
        op_b_store = 7'b0100011, // S store 
        op_b_imm   = 7'b0010011, // I arith ops with register/immediate operands 
        op_b_reg   = 7'b0110011, // R arith ops with register operands 
        //op_b_mul   = 7'b0110011, // R multiply operation
        op_b_csr   = 7'b1110011  // I control and status register 
    } rv32i_op_b_t;

    typedef enum bit [2:0] {
        beq  = 3'b000,
        bne  = 3'b001,
        blt  = 3'b100,
        bge  = 3'b101,
        bltu = 3'b110,
        bgeu = 3'b111
    } branch_funct3_t;

    typedef enum bit [2:0] {
        lb  = 3'b000,
        lh  = 3'b001,
        lw  = 3'b010,
        lbu = 3'b100,
        lhu = 3'b101
    } load_funct3_t;

    typedef enum bit [2:0] {
        sb = 3'b000,
        sh = 3'b001,
        sw = 3'b010
    } store_funct3_t;

    typedef enum bit [2:0] {
        add  = 3'b000, //check bit 30 for sub if op_reg opcode
        sll  = 3'b001,
        slt  = 3'b010,
        sltu = 3'b011,
        axor = 3'b100,
        sr   = 3'b101, //check bit 30 for logical/arithmetic
        aor  = 3'b110,
        aand = 3'b111
    } arith_funct3_t;

    typedef enum bit [2:0] {
        alu_add = 3'b000,
        alu_sll = 3'b001,
        alu_sra = 3'b010,
        alu_sub = 3'b011,
        alu_xor = 3'b100,
        alu_srl = 3'b101,
        alu_or  = 3'b110,
        alu_and = 3'b111
    } alu_ops;

    // rvfi struct

    typedef struct packed {
        logic           monitor_valid;
        logic   [63:0]  monitor_order;
        logic   [31:0]  monitor_inst;
        logic   [4:0]   monitor_rs1_addr;
        logic   [4:0]   monitor_rs2_addr;
        logic   [31:0]  monitor_rs1_rdata;
        logic   [31:0]  monitor_rs2_rdata;
        logic           monitor_regf_we;
        logic   [4:0]   monitor_rd_addr;
        logic   [31:0]  monitor_rd_wdata;
        logic   [31:0]  monitor_pc_rdata;
        logic   [31:0]  monitor_pc_wdata;
        logic   [31:0]  monitor_mem_addr;
        logic   [3:0]   monitor_mem_rmask;
        logic   [3:0]   monitor_mem_wmask;
        logic   [31:0]  monitor_mem_rdata;
        logic   [31:0]  monitor_mem_wdata;
    } rvfi_data_t;

    // Piplined core register defs 

    typedef struct packed {
        bit [31:0] pc;
        bit        branch_pred;
        bit [31:0] predicted_pc;
        
        rvfi_data_t rvfi;
    } if_id_reg_t;

    typedef struct packed {

        bit [31:0]  pc;
        bit         branch_pred;
        bit [31:0]  predicted_pc;

        bit         regf_we;

        bit         mem_read;
        bit         mem_write;
        bit         branch;
        bit         jalr;
        bit         jal;
        
        bit         alu_src;
        bit [2:0]   alu_op;
        bit         alu_or_cmp;

        bit [31:0]  rs1_v;
        bit [31:0]  rs2_v;
        bit [31:0]  imm;

        bit [4:0]   rd_s;
        bit [4:0]   rs1_s;
        bit [4:0]   rs2_s;

        bit         funct7_bit;
        bit [2:0]   funct3;

        bit [6:0]   opcode;

        bit [31:0]  jalr_imm;
        bit [31:0]  jal_imm;
        
        rvfi_data_t rvfi;
    } id_ex_reg_t;

    

    typedef struct packed {

        bit         regf_we;
        bit         mem_read;
        bit         mem_write;

        bit [31:0]  alu_result;
        bit [31:0]  rs2_v;

        bit [4:0]   rd_s;

        bit [2:0]   funct3;
        
        rvfi_data_t rvfi;

    } ex_mem_reg_t;

    typedef struct packed {
        
        bit         regf_we;

        bit [4:0]   rd_s;

        bit         mem_read;
        bit [31:0]  rd_v;
        bit [31:0]  read_data;

        rvfi_data_t rvfi;
        
    } mem_wb_reg_t;


    // OOO core structs + parameters
    parameter IQ_DATA_WIDTH = 64;
    parameter IQ_DEPTH = 16;
    parameter NUM_REGS = 64;
    parameter ROB_SIZE = 16;
    parameter ALU_STATION_DEPTH = 16;
    parameter LD_ST_QUEUE_DEPTH = 16;

    typedef struct packed {
        bit       busy; // 1
        bit [6:0] opcode; // 1 + 7 = 8
        bit [$clog2(NUM_REGS)-1:0] phys_rd; // 8 + 8  = 16
        bit [2:0] funct3; // 16 + 3 = 19
        bit [$clog2(NUM_REGS)-1:0] phys_rs1; // 19 + 8 = 27
        bit       rs1_valid; // 27 + 1 = 28
        bit [$clog2(NUM_REGS)-1:0] phys_rs2; // 28 + 8 = 34 --- ???? cant math -> 36
        bit       rs2_valid; // 34 + 1 = 35
        bit [$clog2(ROB_SIZE)-1:0] rob_index;
        bit [31:0] imm; // 39 + 32 = 71
        bit [4:0] arch_rs1; // 71 + 5 = 76
        bit [4:0] arch_rs2; // 76 + 5 = 81
        bit [4:0] arch_rd; // 81 + 5 = 86
        bit       regf_we; // 86 + 1 = 87
        bit       aluc; // 87 + 1 = 88
        bit [6:0] funct7; // 88 + 7 = 95
        bit [31:0] pc;
        bit [63:0] order;
        bit [31:0] inst;
        bit branch_pred;
    } reservation_station_entry_t;

    typedef struct packed {
        bit valid;
        bit [63:0] order;
        bit [31:0] inst;
        bit [4:0] rs1_addr;
        bit [4:0] rs2_addr;
        bit [31:0] rs1_rdata;
        bit [31:0] rs2_rdata;
        bit [4:0] rd_addr;
        bit [31:0] rd_wdata;
        bit [31:0] pc_rdata;
        bit [31:0] pc_wdata;
        bit [31:0] mem_addr;
        bit [3:0] mem_rmask;
        bit [3:0] mem_wmask;
        bit [31:0] mem_rdata;
        bit [31:0] mem_wdata;
    } rvfi_commit_packet_t;
 
    typedef struct packed {
        bit [$clog2(NUM_REGS)-1:0] phys_rd; // 8
        bit [31:0] phys_rd_val; // 8 + 32 = 40
        bit [$clog2(ROB_SIZE)-1:0] rob_index; // 40 + 4 = 44
        bit [4:0] arch_rd; // 44 + 5 = 49
        bit       regf_we; // 49 + 1 = 50
        bit       alu_or_cmp_op; // 50 + 1 = 51
        bit execute_valid;
        bit branch_mismatch;
        rvfi_commit_packet_t rvfi;
    } data_bus_package_t;

    typedef struct packed {
        bit       done; // 1
        bit [31:0] pc; // 1 + 32 = 33
        bit [31:0] instruction; // 33 + 32 = 65
        bit [$clog2(NUM_REGS)-1:0] phys_rd; // 65 +
        bit [4:0] arch_rd;
        bit branch_mismatch;
        // rvfi_commit_packet_t rvfi;
    } rob_entry_t;

    typedef union packed {
        bit [37:0] word;

        struct packed {
            bit [1:0] extra;
            bit [11:0] i_imm;
            bit [6:0] rs1;
            bit [2:0] funct3;
            bit [6:0] rd;
            bit [6:0] opcode;
        } i_type;

        struct packed {
            bit [6:0] funct7;
            bit [6:0] rs2;
            bit [6:0] rs1;
            bit [2:0] funct3;
            bit [6:0] rd;
            bit [6:0] opcode;
        } r_type;

        struct packed {
            bit [1:0] extra;
            bit [11:5] imm_s_top;
            bit [6:0]  rs2;
            bit [6:0]  rs1;
            bit [2:0]  funct3;
            bit [4:0]  imm_s_bot;
            bit [6:0] opcode;
        } s_type;

        struct packed {
            bit [1:0] extra;
            bit [6:0] imm_b_top;
            bit [6:0] rs2;
            bit [6:0] rs1;
            bit [2:0] funct3;
            bit [4:0] imm_b_bot;
            bit [6:0] opcode;
        } b_type;

        struct packed {
            bit [3:0] extra;
            bit [19:0] imm;
            bit [6:0]  rd;
            bit [6:0] opcode;
        } j_type;

    } instr_t;

    typedef struct packed {
        bit [6:0] opcode; // can and should only have ld or st opcodes
        bit [2:0] funct3; // 8/16/32 tings
        // bit [31:0] dmem_addr_or_rdwdata; // if ld dmem_addr, if st rd_wdata
        bit rs1_ready;
        bit [$clog2(NUM_REGS)-1:0] pr1_s_ld_st;
        bit [4:0] arch_rs1;
        
        bit rs2_ready;
        bit [$clog2(NUM_REGS)-1:0] pr2_s_ld_st;
        bit [4:0] arch_rs2;

        bit [$clog2(NUM_REGS)-1:0] phys_rd;
        bit [4:0] arch_rd;

        bit [$clog2(ROB_SIZE)-1:0] rob_index;
        bit [31:0] pc;
        bit [31:0] imm;
        bit [63:0] order;
        bit [31:0] inst;
    } ld_st_queue_t;

    // typedef union packed {
    //     bit [36:0] word;

    //     struct packed {
    //         bit [2:0] extra;
    //         bit [11:0] i_imm;
    //         bit [$clog2(NUM_REGS)-1:0] rs1;
    //         bit [2:0] funct3;
    //         bit [$clog2(NUM_REGS)-1:0] rd;
    //         bit [6:0] opcode;
    //     } i_type;

    //     struct packed {
    //         bit [1:0] extra;
    //         bit [6:0] funct7;
    //         bit [$clog2(NUM_REGS)-1:0] rs2;
    //         bit [$clog2(NUM_REGS)-1:0] rs1;
    //         bit [2:0] funct3;
    //         bit [$clog2(NUM_REGS)-1:0] rd;
    //         bit [6:0] opcode;
    //     } r_type;

    //     struct packed {
    //         bit [2:0] extra;
    //         bit [11:5] imm_s_top;
    //         bit [$clog2(NUM_REGS)-1:0]  rs2;
    //         bit [$clog2(NUM_REGS)-1:0]  rs1;
    //         bit [2:0]  funct3;
    //         bit [4:0]  imm_s_bot;
    //         bit [6:0] opcode;
    //     } s_type;

    //     struct packed {
    //         bit [2:0] extra;
    //         bit [6:0] imm_b_top;
    //         bit [$clog2(NUM_REGS)-1:0] rs2;
    //         bit [$clog2(NUM_REGS)-1:0] rs1;
    //         bit [2:0] funct3;
    //         bit [4:0] imm_b_bot;
    //         bit [6:0] opcode;
    //     } b_type;

    //     struct packed {
    //         bit [3:0] extra;
    //         bit [19:0] imm;
    //         bit [$clog2(NUM_REGS)-1:0]  rd;
    //         bit [6:0] opcode;
    //     } j_type;

    // } instr_t;

    // typedef struct packed {
    //     bit valid;
    //     bit [63:0] order;
    //     bit [31:0] inst;
    //     bit [4:0] rs1_addr;
    //     bit [4:0] rs2_addr;
    //     bit [31:0] rs1_rdata;
    //     bit [31:0] rs2_rdata;
    //     bit [4:0] rd_addr;
    //     bit [31:0] rd_wdata;
    //     bit [31:0] pc_rdata;
    //     bit [31:0] pc_wdata;
    //     bit [31:0] mem_addr;
    //     bit [3:0] mem_rmask;
    //     bit [3:0] mem_wmask;
    //     bit [31:0] mem_rdata;
    //     bit [31:0] mem_wdata;
    // } rvfi_commit_packet_t;

    // typedef struct packed {
    //     bit busy;
        
    //     bit [4:0] arch_rd;
    //     bit [$clog2(NUM_REGS)-1:0] phys_rd;

    //     bit rs1_valid;
    //     bit [$clog2(NUM_REGS)-1:0] phys_rs1;

    //     bit rs2_valid;
    //     bit [$clog2(NUM_REGS)-1:0] phys_rs2;

    //     bit [6:0] opcode;
    //     bit [2:0] funct3;
    //     bit [6:0] funct7_bit;

    //     bit [31:0] pc;
    //     bit [31:0] imm;

    //     bit branch_pred;
    //     bit regf_we;
    //     bit aluc;

    //     bit [$clog2(ROB_SIZE)-1:0] rob_index;

    //     rvfi_commit_packet_t rvfi;
    // } reservation_station_entry_t;

    // typedef struct packed {
    //     bit execute_valid;
        
    //     bit [4:0] arch_rd;
    //     bit [$clog2(NUM_REGS)-1:0] phys_rd;

    //     bit regf_we;
    //     bit [31:0] phys_rd_val;

    //     bit branch_mispredict;
    //     bit [$clog2(ROB_SIZE)-1:0] rob_index;
    //     rvfi_commit_packet_t rvfi;
    // } data_bus_package_t;

    // typedef struct packed {
    //     bit done;
        
    //     bit [4:0] arch_rd;
    //     bit [$clog2(NUM_REGS)-1:0] phys_rd;

    //     bit branch_mispredict;
    // } rob_entry_t;
    
endpackage

package pcmux;
    typedef enum bit [1:0] {
        pc_plus4  = 2'b00
        ,alu_out  = 2'b01
        ,alu_mod2 = 2'b10
    } pcmux_sel_t;
endpackage

package marmux;
    typedef enum bit {
        pc_out = 1'b0
        ,alu_out = 1'b1
    } marmux_sel_t;
endpackage

package cmpmux;
    typedef enum bit {
        rs2_out = 1'b0
        ,i_imm = 1'b1
    } cmpmux_sel_t;
endpackage

package alumux;
    typedef enum bit {
        rs1_out = 1'b0
        ,pc_out = 1'b1
    } alumux1_sel_t;

    typedef enum bit [2:0] {
        i_imm    = 3'b000
        ,u_imm   = 3'b001
        ,b_imm   = 3'b010
        ,s_imm   = 3'b011
        ,j_imm   = 3'b100
        ,rs2_out = 3'b101
    } alumux2_sel_t;
endpackage

package regfilemux;
    typedef enum bit [3:0] {
        alu_out   = 4'b0000
        ,br_en    = 4'b0001
        ,u_imm    = 4'b0010
        ,lw       = 4'b0011
        ,pc_plus4 = 4'b0100
        ,lb        = 4'b0101
        ,lbu       = 4'b0110  // unsigned byte
        ,lh        = 4'b0111
        ,lhu       = 4'b1000  // unsigned halfword
    } regfilemux_sel_t;
endpackage


package rv32i_types_1;

    // Mux types are in their own packages to prevent identiier collisions
    // e.g. pcmux::pc_plus4 and regfilemux::pc_plus4 are seperate identifiers
    // for seperate enumerated types
    import pcmux::*;
    import marmux::*;
    import cmpmux::*;
    import alumux::*;
    import regfilemux::*;

    typedef enum bit [6:0] {
        op_lui   = 7'b0110111, // load upper immediate (U type)
        op_auipc = 7'b0010111, // add upper immediate PC (U type)
        op_jal   = 7'b1101111, // jump and link (J type)
        op_jalr  = 7'b1100111, // jump and link register (I type)
        op_br    = 7'b1100011, // branch (B type)
        op_load  = 7'b0000011, // load (I type)
        op_store = 7'b0100011, // store (S type)
        op_imm   = 7'b0010011, // arith ops with register/immediate operands (I type)
        op_reg   = 7'b0110011  // arith ops with register operands (R type)
    } rv32i_opcode;

    typedef enum bit [2:0] {
        beq  = 3'b000,
        bne  = 3'b001,
        blt  = 3'b100,
        bge  = 3'b101,
        bltu = 3'b110,
        bgeu = 3'b111
    } branch_funct3_t;

    typedef enum bit [2:0] {
        lb  = 3'b000,
        lh  = 3'b001,
        lw  = 3'b010,
        lbu = 3'b100,
        lhu = 3'b101
    } load_funct3_t;

    typedef enum bit [2:0] {
        sb = 3'b000,
        sh = 3'b001,
        sw = 3'b010
    } store_funct3_t;

    typedef enum bit [2:0] {
        add  = 3'b000, //check bit 30 for sub if op_reg opcode
        sll  = 3'b001,
        slt  = 3'b010,
        sltu = 3'b011,
        axor = 3'b100,
        sr   = 3'b101, //check bit 30 for logical/arithmetic
        aor  = 3'b110,
        aand = 3'b111
    } arith_funct3_t;

    typedef enum bit [2:0] {
        alu_add = 3'b000,
        alu_sll = 3'b001,
        alu_sra = 3'b010,
        alu_sub = 3'b011,
        alu_xor = 3'b100,
        alu_srl = 3'b101,
        alu_or  = 3'b110,
        alu_and = 3'b111
    } alu_ops;

endpackage : rv32i_types_1


/*
Every reservation station you add
 - Add ports to rob
 - Add ports to rat to read valids
 - Add ports to rat update valid
 - Add port to phys regfile for loads
*/