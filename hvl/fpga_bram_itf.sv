interface fpga_bram_itf #(
    parameter   ADDRESS_DATA_WIDTH = 33 // 64-bit data / 32-bit addr
)(
    input   bit         fpga_clk,
    input   bit         rst
);

    // Memory -> Controller
    logic                            r_en_CPU_to_FPGA_FIFO;
    logic                            w_en_FPGA_to_CPU_FIFO;

    // Controller -> Memory
    logic                            empty_CPU_to_FPGA_FIFO;
    logic                            full_FPGA_to_CPU_FIFO;

    // Controller <-> Memory
    wire  [ADDRESS_DATA_WIDTH-1:0]   address_data_bus;

    bit                         error = 1'b0;

    modport mem (
        input                   fpga_clk,
        input                   rst,

        input                   empty_CPU_to_FPGA_FIFO,
        input                   full_FPGA_to_CPU_FIFO,

        output                  r_en_CPU_to_FPGA_FIFO,
        output                  w_en_FPGA_to_CPU_FIFO,

        inout                   address_data_bus,

        output                  error
    );

endinterface