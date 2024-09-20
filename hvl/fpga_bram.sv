// Single Port RAM with Native Interface
module fpga_bram #(
    parameter   DATA_WIDTH = 64, // 64 Bits
    parameter   ADDRESS_WIDTH = 32 // 2^32 - 1 = 4,294,967,295 elements
)(
    fpga_bram_itf.mem itf
);

    logic [DATA_WIDTH-1:0] internal_memory_array [logic [(2**ADDRESS_WIDTH)-1:0]];

    task automatic reset();
        automatic string memfile = {getenv("ECE411_MEMLST"), "_8.lst"};
        automatic string memfile1 = {getenv("ECE411_MEMLST_PIPE"), "_8.lst"};
        internal_memory_array.delete();
        $readmemh(memfile, internal_memory_array);
        $readmemh(memfile1, internal_memory_array);
        $display("using memory file %s", memfile);
        $display("using memory file %s", memfile1);
    endtask

    always @(posedge itf.clk iff itf.rst) begin
        reset();
    end

    typedef enum logic {  
        idle,
        service_read,
        service_write
    } state, next_state;

    always_ff @(posedge itf.clk) begin
        if(itf.rst) begin
            state <= idle;
        end else begin
            state <= next_state;
        end 
    end

    always_comb begin
        unique case(state)
            idle: begin
                if(itf.read_en_i) begin
                    next_state = service_read;
                end else if(itf.write_en_i) begin
                    next_state = service_write;
                end else begin
                    next_state = state;
                end
            end
            service_read: begin
                if(resp_o) begin
                    next_state = idle;
                end
            end
            service_write: begin
                if(resp_o) begin
                    next_state = idle;
                end
            end
            default: next_state = state;
        endcase
    end

    always_ff @(posedge itf.clk) begin
        if(itf.ena) begin
            if(itf.wea) begin
                internal_memory_array[itf.addra] <= itf.dina;
            end else begin
                itf.douta <= internal_memory_array[itf.addra];
            end
        end else begin
            itf.douta <= 'x;
        end
    end

    always @(posedge itf.clk iff !itf.rst) begin
        if(itf.ena) begin
            if($isunknown(itf.addra)) begin
                $error("Address contains 'x");
                itf.error <= 1'b1;
            end else if(itf.wea) begin
                if($isunknown(itf.dina)) begin
                    $error("Input data contains 'x");
                    itf.error <= 1'b1;
                end
            end
        end
    end

endmodule