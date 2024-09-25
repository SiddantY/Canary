interface fpga_bram_itf #(
    parameter   ADDRESS_DATA_WIDTH = 32 // 64-bit data / 32-bit addr
)(
    input   bit         clk,
    input   bit         rst
);

    // Memory -> Controller
    logic  [ADDRESS_DATA_WIDTH-1:0]  address_data_bus_c_to_m;
    logic                            resp_m_to_c;

    // Controller -> Memory
    logic  [ADDRESS_DATA_WIDTH-1:0]  address_data_bus_m_to_c;
    logic                            address_on_c_to_m;
    logic                            data_on_c_to_m;
    logic                            read_en_c_to_m;
    logic                            write_en_c_to_m;

    // logic  [ADDRESS_WIDTH-1:0]  addra;
    // logic  [DATA_WIDTH-1:0]     dina;
    // logic                       wea;       
    // logic                       ena;       
    // logic  [DATA_WIDTH-1:0]     douta;   

    bit                         error = 1'b0;

    modport mem (
        input                   clk,
        input                   rst,

        input                   address_data_bus_c_to_m,
        input                   address_on_c_to_m,
        input                   data_on_c_to_m,
        input                   read_en_c_to_m,
        input                   write_en_c_to_m,

        output                  address_data_bus_m_to_c,
        output                  resp_m_to_c,
        output                  error
    );

endinterface