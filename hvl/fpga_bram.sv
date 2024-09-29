// Single Port RAM with Native Interface
module fpga_bram #(
    parameter   DATA_WIDTH = 64,
    parameter   ADDRESS_WIDTH = 32 
)(
    fpga_bram_itf.mem itf
);

    logic [DATA_WIDTH-1:0] internal_memory_array [logic [ADDRESS_WIDTH-1:0]];
    logic [DATA_WIDTH-1:0] dina;
    logic [ADDRESS_WIDTH-1:0] addra;
    logic store_address;
    logic clear_address;
    logic store_data;
    logic store_data_1;
    logic clear_data;
    logic enable_memory;
    logic [31:0] wburst_counter;
    logic [31:0] rburst_counter;
    logic sub_rburst_counter;

    task automatic reset();
        automatic string memfile = {getenv("ECE411_MEMLST"), "_8.lst"};
        automatic string memfile1 = {getenv("ECE411_MEMLST_PIPE"), "_8.lst"};
        internal_memory_array.delete();
        $readmemh(memfile1, internal_memory_array);
        $readmemh(memfile, internal_memory_array);
        $display("using memory file %s", memfile);
        $display("using memory file %s", memfile1);
    endtask

    always @(posedge itf.clk iff itf.rst) begin
        reset();
    end

    typedef enum logic [4:0] {  
        idle,
        read_address,
        read_data,
        read_data_1,
        read_data_2,
        read_data_3,
        read_data_4,
        read_data_5,
        read_data_6,
        read_data_7,
        read_data_8,
        read_data_from_memory,
        read_data_from_memory2,
        read_data_from_memory3,
        read_data_from_memory4,
        read_data_from_memory5,
        read_data_from_memory6,
        read_data_from_memory7,
        read_data_from_memory8,
        respond
    } state_t;

    state_t state, next_state;

    always_ff @(posedge itf.clk) begin
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
        enable_memory = 1'b0;
        itf.resp_m_to_c = 1'b0;
        rburst_counter = 32'd0;
        wburst_counter = 32'd0;
        sub_rburst_counter = 1'b0;
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
                    itf.resp_m_to_c = 1'b1;
                    if(itf.write_en_c_to_m) begin
                        next_state = read_data;
                    end else begin
                        next_state = read_data_from_memory; // Move to perform a read operation and respond
                    end
                end else begin
                    next_state = read_address; // Maintain state until address is on bus
                end
            end
            read_data: begin
                if(itf.data_on_c_to_m) begin
                    // Store Data
                    // store_data = 1'b1;
                    itf.resp_m_to_c = 1'b1;
                    next_state = read_data_1;
                end else begin
                    next_state = read_data; // Maintain state until data is on bus
                end
            end
            read_data_1: begin
                if(itf.data_on_c_to_m) begin
                    // Store Data
                    // enable_memory = 1'b1;
                    store_data = 1'b1;
                    itf.resp_m_to_c = 1'b1;
                    next_state = read_data_2;
                end else begin
                    next_state = read_data_1;
                end
            end
            read_data_2: begin
                if(itf.data_on_c_to_m) begin
                    // Store Data
                    store_data_1 = 1'b1;
                    itf.resp_m_to_c = 1'b1;
                    next_state = read_data_3;
                end else begin
                    next_state = read_data_2; // Maintain state until data is on bus
                end
            end
            read_data_3: begin
                if(itf.data_on_c_to_m) begin
                    // Store Data
                    enable_memory = 1'b1;
                    wburst_counter = 32'd0;
                    store_data = 1'b1;
                    itf.resp_m_to_c = 1'b1;
                    next_state = read_data_4;
                end else begin
                    next_state = read_data_3;
                end
            end
            read_data_4: begin
                if(itf.data_on_c_to_m) begin
                    // Store Data
                    store_data_1 = 1'b1;
                    itf.resp_m_to_c = 1'b1;
                    next_state = read_data_5;
                end else begin
                    next_state = read_data_4; // Maintain state until data is on bus
                end
            end
            read_data_5: begin
                if(itf.data_on_c_to_m) begin
                    // Store Data
                    enable_memory = 1'b1;
                    wburst_counter = 32'd1;
                    store_data = 1'b1;
                    itf.resp_m_to_c = 1'b1;
                    next_state = read_data_6;
                end else begin
                    next_state = read_data_5;
                end
            end
            read_data_6: begin
                if(itf.data_on_c_to_m) begin
                    // Store Data
                    store_data_1 = 1'b1;
                    itf.resp_m_to_c = 1'b1;
                    next_state = read_data_7;
                end else begin
                    next_state = read_data_6; // Maintain state until data is on bus
                end
            end
            read_data_7: begin
                if(itf.data_on_c_to_m) begin
                    // Store Data
                    enable_memory = 1'b1;
                    wburst_counter = 32'd2;
                    store_data = 1'b1;
                    itf.resp_m_to_c = 1'b1;
                    next_state = read_data_8;
                end else begin
                    next_state = read_data_7;
                end
            end
            read_data_8: begin
                if(itf.data_on_c_to_m) begin
                    // Store Data
                    store_data_1 = 1'b1;
                    itf.resp_m_to_c = 1'b1;
                    next_state = respond;
                end else begin
                    next_state = read_data_1;
                end
            end
            read_data_from_memory: begin
                enable_memory = 1'b1;
                rburst_counter = 32'd0;
                sub_rburst_counter = 1'b0;
                next_state = read_data_from_memory2;
            end
            read_data_from_memory2: begin
                enable_memory = 1'b1;
                itf.resp_m_to_c = 1'b1;
                rburst_counter = 32'd0;
                sub_rburst_counter = 1'b1;
                next_state = read_data_from_memory3;
            end
            read_data_from_memory3: begin
                enable_memory = 1'b1;
                itf.resp_m_to_c = 1'b1;
                rburst_counter = 32'd1;
                sub_rburst_counter = 1'b0;
                next_state = read_data_from_memory4;
            end
            read_data_from_memory4: begin
                enable_memory = 1'b1;
                itf.resp_m_to_c = 1'b1;
                rburst_counter = 32'd1;
                sub_rburst_counter = 1'b1;
                next_state = read_data_from_memory5;
            end

            read_data_from_memory5: begin
                enable_memory = 1'b1;
                itf.resp_m_to_c = 1'b1;
                rburst_counter = 32'd2;
                sub_rburst_counter = 1'b0;
                next_state = read_data_from_memory6;
            end
            read_data_from_memory6: begin
                enable_memory = 1'b1;
                itf.resp_m_to_c = 1'b1;
                rburst_counter = 32'd2;
                sub_rburst_counter = 1'b1;
                next_state = read_data_from_memory7;
            end

            read_data_from_memory7: begin
                enable_memory = 1'b1;
                itf.resp_m_to_c = 1'b1;
                rburst_counter = 32'd3;
                sub_rburst_counter = 1'b0;
                next_state = read_data_from_memory8;
            end
            read_data_from_memory8: begin
                enable_memory = 1'b1;
                itf.resp_m_to_c = 1'b1;
                rburst_counter = 32'd3;
                sub_rburst_counter = 1'b1;
                next_state = respond;
            end

            respond: begin
                enable_memory = 1'b1;
                wburst_counter = 32'd3;
                itf.resp_m_to_c = 1'b1;
                next_state = idle;
            end
            default: begin
                clear_address = 1'b0;
                store_address = 1'b0;
                clear_data = 1'b0;
                store_data = 1'b0;
                itf.resp_m_to_c  = 1'b0;
                enable_memory = 1'b0;
                next_state = state;
            end
        endcase
    end

    always_ff @(posedge itf.clk) begin
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

    always_ff @(posedge itf.clk) begin
        if(enable_memory) begin
            if(itf.write_en_c_to_m) begin
                internal_memory_array[(addra + (32'd8 *wburst_counter)) / 32'd8] <= dina;
            end else if(itf.read_en_c_to_m)begin
                itf.address_data_bus_m_to_c <= internal_memory_array[(addra + (32'd8 *rburst_counter)) / 32'd8][32*sub_rburst_counter +: 32];
            end else begin
                itf.address_data_bus_m_to_c <= 'x;
            end
        end else begin
            itf.address_data_bus_m_to_c <= 'x;
        end
    end

    // always @(posedge itf.clk iff !itf.rst) begin
    //     if(enable_memory) begin
    //         if($isunknown(addra)) begin
    //             $error("Address contains 'x");
    //             itf.error <= 1'b1;
    //         end else if(itf.write_en_c_to_m) begin
    //             if($isunknown(dina)) begin
    //                 $error("Input data contains 'x");
    //                 itf.error <= 1'b1;
    //             end
    //         end
    //     end
    // end

endmodule