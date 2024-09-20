// Single Port RAM with Native Interface
module fpga_bram #(
    parameter   DATA_WIDTH = 64, // 64 Bits
    parameter   ADDRESS_WIDTH = 32 // 2^32 - 1 = 4,294,967,295 elements
)(
    fpga_bram_itf.mem itf
);

    logic [DATA_WIDTH-1:0] internal_memory_array [logic [(2**ADDRESS_WIDTH)-1:0]];
    logic [DATA_WIDTH-1:0] dina;
    logic [ADDRESS_WIDTH-1:0] addra;
    logic store_address;
    logic clear_address;
    logic store_data;
    logic clear_data;

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

    typedef enum logic [1:0] {  
        idle,
        read_address,
        read_data,
        respond
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
                clear_address = 1'b1;
                clear_data = 1'b1;
                if(itf.read_en_i | itf.write_en_i) begin
                    next_state = read_address;
                end else begin
                    next_state = idle;
                end
            end
            read_address: begin
                if(itf.address_on_i) begin
                    // Store Address
                    store_address = 1'b1;
                    if(itf.write_en_i) begin
                        next_state = read_data;
                    end else begin
                        next_state = respond;
                    end
                end else begin
                    next_state = read_address;
                end
            end
            read_data: begin
                if(itf.data_on_i) begin
                    // Store Data
                    store_data = 1'b1;
                    next_state = respond
                end else begin
                    next_state = read_data;
                end
            end
            respond: begin
                next_state = idle;
            end
            default: next_state = state;
        endcase
    end

    always_ff @(posedge itf.clk) begin
        if(store_address) begin
            addra <= itf.address_data_bus_i;
        end else if(clear_address) begin
            addra <= 'x;
        end

        if(store_data) begin
            dina <= itf.address_data_bus_i;
        end else if(clear_data) begin
            dina <= 'x;
        end

    end


    always_ff @(posedge itf.clk) begin
        if(itf.ena) begin
            if(itf.wea) begin
                internal_memory_array[addra] <= dina;
            end else begin
                address_data_bus_o <= internal_memory_array[addra];
            end
        end else begin
            address_data_bus_o <= 'x;
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