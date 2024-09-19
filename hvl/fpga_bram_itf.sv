interface fpga_bram_itf #(
    parameter   DATA_WIDTH = 64, // 64 Bits
    parameter   ADDRESS_WIDTH = 32 // 2^32 - 1 = 4,294,967,295 elements
)(
    input   bit         clk,
    input   bit         rst
);

    logic  [ADDRESS_WIDTH-1:0]  addra;
    logic  [DATA_WIDTH-1:0]     dina;
    logic                       wea;       
    logic                       ena;       
    logic  [DATA_WIDTH-1:0]     douta;   

    bit                         error = 1'b0;

    modport mem (
        input                   clk, //clka
        input                   rst,
        input                   addra,
        input                   dina,
        input                   wea,        
        input                   ena,        
        output                  douta,   
        output                  error
    );

endinterface