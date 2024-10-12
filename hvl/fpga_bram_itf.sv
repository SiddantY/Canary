interface fpga_bram_itf #(
    parameter   ADDRESS_DATA_WIDTH = 32 // 64-bit data / 32-bit addr
)(
    input   bit         fpga_clk,
    input   bit         rst
);

    // Memory -> Controller
    logic  [ADDRESS_DATA_WIDTH-1:0]  address_data_bus_c_to_m;
    logic                            resp_m_to_c;
    logic                            r_en_CPU_to_FPGA_FIFO;
    logic                            w_en_FPGA_to_CPU_FIFO;
    logic [35:0]                     data_in_FPGA_to_CPU_FIFO;

    // Controller -> Memory
    logic                            full_FPGA_to_CPU_FIFO;
    logic  [ADDRESS_DATA_WIDTH-1:0]  address_data_bus_m_to_c;
    logic                            address_on_c_to_m;
    logic                            data_on_c_to_m;
    logic                            read_en_c_to_m;
    logic                            write_en_c_to_m;
    logic                            empty_CPU_to_FPGA_FIFO;
    logic [35:0]                     data_out_CPU_to_FPGA_FIFO;

    // logic  [ADDRESS_WIDTH-1:0]  addra;
    // logic  [DATA_WIDTH-1:0]     dina;
    // logic                       wea;       
    // logic                       ena;       
    // logic  [DATA_WIDTH-1:0]     douta;   

    bit                         error = 1'b0;

    modport mem (
        input                   fpga_clk,
        input                   rst,

        input                   address_data_bus_c_to_m,
        input                   address_on_c_to_m,
        input                   data_on_c_to_m,
        input                   read_en_c_to_m,
        input                   write_en_c_to_m,
        input                   empty_CPU_to_FPGA_FIFO,
        input                   full_FPGA_to_CPU_FIFO,
        input                   data_out_CPU_to_FPGA_FIFO,

        output                  address_data_bus_m_to_c,
        output                  resp_m_to_c,
        output                  r_en_CPU_to_FPGA_FIFO,
        output                  w_en_FPGA_to_CPU_FIFO,
        output                  data_in_FPGA_to_CPU_FIFO,
        output                  error
    );

endinterface