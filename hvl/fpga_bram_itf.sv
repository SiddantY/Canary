interface fpga_bram_itf #(
    parameter   ADDRESS_DATA_WIDTH = 64 // 64-bit data / 32-bit addr
)(
    input   bit         clk,
    input   bit         rst
);

    // Memory -> Controller
    logic  [ADDRESS_DATA_WIDTH-1:0]  address_data_bus_o;
    logic                            resp_o;

    // Controller -> Memory
    logic  [ADDRESS_DATA_WIDTH-1:0]  address_data_bus_i;
    logic                            address_on_i;
    logic                            data_on_i;
    logic                            read_en_i;
    logic                            write_en_i;

    // logic  [ADDRESS_WIDTH-1:0]  addra;
    // logic  [DATA_WIDTH-1:0]     dina;
    // logic                       wea;       
    // logic                       ena;       
    // logic  [DATA_WIDTH-1:0]     douta;   

    bit                         error = 1'b0;

    modport mem (
        input                   clk,
        input                   rst,

        input                   address_data_bus_i;
        input                   address_on_i;
        input                   data_on_i;
        input                   read_en_i;
        input                   write_en_i;

        output                   address_data_bus_o;
        output                   resp_o;

        // input                   addra,
        // input                   dina,
        // input                   wea,        
        // input                   ena,        
        // output                  douta,   
        output                  error
    );

endinterface