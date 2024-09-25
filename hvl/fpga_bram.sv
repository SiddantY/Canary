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
    logic store_data_1;
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

    always @(posedge itf.fpga_clk iff itf.rst) begin
        reset();
    end

    enum logic [2:0] {  
        idle,
        read_address,
        read_data,
        read_data_1,
        respond
    } state, next_state;

    always_ff @(posedge itf.fpga_clk) begin
        if(itf.rst) begin
            state <= idle;
        end else begin
            state <= next_state;
        end 
    end

    always_comb begin
        store_address = 1'b0;
        clear_address = 1'b0;
        store_data = 1'b0;
        store_data_1 = 1'b0;
        clear_data = 1'b0;
        unique case(state)
            idle: begin
                clear_address = 1'b1;
                clear_data = 1'b1;
                if(itf.read_en_c_to_m | itf.write_en_c_to_m) begin
                    next_state = read_address;
                end else begin
                    next_state = idle;
                end
            end
            read_address: begin
                if(itf.address_on_c_to_m) begin
                    // Store Address
                    store_address = 1'b1;
                    if(itf.write_en_c_to_m) begin
                        next_state = read_data;
                    end else begin
                        next_state = respond;
                    end
                end else begin
                    next_state = read_address;
                end
            end
            read_data: begin
                if(itf.data_on_c_to_m) begin
                    // Store Data
                    store_data = 1'b1;
                    next_state = read_data_1;
                end else begin
                    next_state = read_data;
                end
            end
            read_data_1: begin
                if(itf.data_on_c_to_m) begin
                    // Store Data
                    store_data_1 = 1'b1;
                    next_state = respond;
                end else begin
                    next_state = read_data_1;
                end
            end
            respond: begin
                next_state = idle;
            end
            default: next_state = state;
        endcase
    end

    always_ff @(posedge itf.fpga_clk) begin
        if(store_address) begin
            addra <= itf.address_data_bus_c_to_m;
        end else if(clear_address) begin
            addra <= 'x;
        end

        if(store_data) begin
            dina[31:0] <= itf.address_data_bus_c_to_m;
        end else if(store_data_1) begin
            dina[63:32] <= itf.address_data_bus_c_to_m;
        end else if(clear_data) begin
            dina <= 'x;
        end

    end


    always_ff @(posedge itf.fpga_clk) begin
        if(itf.write_en_c_to_m) begin
            internal_memory_array[addra] <= dina;
        end else if(itf.read_en_c_to_m)begin
            itf.address_data_bus_m_to_c <= internal_memory_array[addra];
        end else begin
            itf.address_data_bus_m_to_c <= 'x;
        end
        
    end

    always @(posedge itf.fpga_clk iff !itf.rst) begin
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