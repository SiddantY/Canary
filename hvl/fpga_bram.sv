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
    // logic store_address;
    // logic clear_address;
    // logic store_data;
    // logic store_data_1;
    // logic clear_data;
    logic enable_memory;
    logic [31:0] wburst_counter;
    logic [31:0] store_wburst_counter;
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

    always @(posedge itf.fpga_clk iff itf.rst) begin
        reset();
    end

    enum logic [4:0] {
        FPGA_IDLE,
        FPGA_READ_ADDR,
        // Read Operation
        FPGA_SEND_MEM,
        // Write Operation
        FPGA_WRITE_MEM
    } state, next_state;

    always_ff @(posedge itf.fpga_clk) begin : update_state
        if(itf.rst) begin
            state <= FPGA_IDLE;
        end else begin
            state <= next_state;
        end
    end

    logic store_address;
    logic clear_address;
    logic clear_data;

    logic [3:0] read_counter;
    logic [3:0] write_counter;
    logic read_from_mem;
    logic write_to_mem;
    logic fpga_resp;
    logic inc_write_counter;

    logic store_write_data;

    always_ff @(posedge itf.fpga_clk) begin
        if(itf.rst) begin
            read_counter <= '0;
            write_counter <= '0;
        end else begin
            if(read_counter == 4'd8) begin
                read_counter <= '0;
            end else begin
                if(read_from_mem) read_counter <= read_counter + 4'd1;
            end

            if(write_counter == 4'd10) begin
                write_counter <= '0;
            end else begin
                if(inc_write_counter) write_counter <= write_counter + 4'd1;
            end
        end
    end


    always_ff @(posedge itf.fpga_clk) begin
        if(itf.rst) begin
            addra <= 'x;
        end else begin
            if(store_address) addra <= itf.address_data_bus_c_to_m;
            else if(clear_address) addra <= 'x;
            
            if(store_write_data) begin
                if(store_wburst_counter) dina[63:32] <= itf.data_out_CPU_to_FPGA_FIFO[31:0];
                else dina[31:0] <= itf.data_out_CPU_to_FPGA_FIFO[31:0];
            end else if(clear_data) begin
                dina <= 'x;
            end
        end
    end

    always_comb begin : next_state_logic
        itf.r_en_CPU_to_FPGA_FIFO = 1'b0;
        itf.w_en_FPGA_to_CPU_FIFO = 1'b0;
        store_address = 1'b0;
        store_write_data = 1'b0;
        read_from_mem = 1'b0;
        write_to_mem = 1'b0;
        rburst_counter = 'x;
        wburst_counter = 'x;
        store_wburst_counter = 'x;
        sub_rburst_counter = 'x;
        fpga_resp = 1'b0;
        inc_write_counter = 1'b0;
        clear_address = 1'b0;
        clear_data = 1'b0;
        next_state = state;
        unique case(state)
            FPGA_IDLE: begin
                clear_address = 1'b1;
                clear_data = 1'b1;
                if(!itf.empty_CPU_to_FPGA_FIFO) begin
                    itf.r_en_CPU_to_FPGA_FIFO = 1'b1;
                    next_state = FPGA_READ_ADDR;
                end else begin
                    next_state = FPGA_IDLE;
                end
            end
            FPGA_READ_ADDR: begin
                store_address = 1'b1;
                if(itf.read_en_c_to_m) begin
                    next_state = FPGA_SEND_MEM;
                end else if(itf.write_en_c_to_m) begin
                    next_state = FPGA_WRITE_MEM;
                end else begin
                    next_state = FPGA_READ_ADDR;
                end
            end
            FPGA_SEND_MEM: begin
                if(read_counter <= 4'd7) begin
                    next_state = FPGA_SEND_MEM;
                    if(!itf.full_FPGA_to_CPU_FIFO) begin
                        read_from_mem = 1'b1;
                        
                        case(read_counter)
                            4'd0: begin rburst_counter = 32'd0; sub_rburst_counter = 1'b0; end
                            4'd1: begin rburst_counter = 32'd0; sub_rburst_counter = 1'b1; itf.w_en_FPGA_to_CPU_FIFO = 1'b1; end
                            4'd2: begin rburst_counter = 32'd1; sub_rburst_counter = 1'b0; itf.w_en_FPGA_to_CPU_FIFO = 1'b1; end
                            4'd3: begin rburst_counter = 32'd1; sub_rburst_counter = 1'b1; itf.w_en_FPGA_to_CPU_FIFO = 1'b1; end
                            4'd4: begin rburst_counter = 32'd2; sub_rburst_counter = 1'b0; itf.w_en_FPGA_to_CPU_FIFO = 1'b1; end
                            4'd5: begin rburst_counter = 32'd2; sub_rburst_counter = 1'b1; itf.w_en_FPGA_to_CPU_FIFO = 1'b1; end
                            4'd6: begin rburst_counter = 32'd3; sub_rburst_counter = 1'b0; itf.w_en_FPGA_to_CPU_FIFO = 1'b1; end
                            4'd7: begin rburst_counter = 32'd3; sub_rburst_counter = 1'b1; itf.w_en_FPGA_to_CPU_FIFO = 1'b1; end
                        endcase
                    end
                end else begin
                    itf.w_en_FPGA_to_CPU_FIFO = 1'b1;
                    next_state = FPGA_IDLE;
                end
            end
            FPGA_WRITE_MEM: begin
                if(write_counter <= 4'd9) begin
                    next_state = FPGA_WRITE_MEM;
                    if(!itf.empty_CPU_to_FPGA_FIFO) begin
                        itf.r_en_CPU_to_FPGA_FIFO = 1'b1;
                        case(write_counter)
                            4'd0: begin inc_write_counter = 1'b1; write_to_mem = 1'b0; store_write_data = 1'b0; store_wburst_counter = 32'd0; wburst_counter = 32'dx; end // Read first 32 bits of data
                            4'd1: begin inc_write_counter = 1'b1; write_to_mem = 1'b0; store_write_data = 1'b1; store_wburst_counter = 32'd0; wburst_counter = 32'dx; end // Read second 32 bits of data, store first 32 bits of data 
                            4'd2: begin inc_write_counter = 1'b1; write_to_mem = 1'b0; store_write_data = 1'b1; store_wburst_counter = 32'd1; wburst_counter = 32'dx; end // Read third 32 bits of data, store second 32 bits of data
                            4'd3: begin inc_write_counter = 1'b1; write_to_mem = 1'b1; store_write_data = 1'b1; store_wburst_counter = 32'd0; wburst_counter = 32'd0; end // Read fourth 32 bits of data, store third 32 bits of data, write first 64 bits to memory
                            4'd4: begin inc_write_counter = 1'b1; write_to_mem = 1'b0; store_write_data = 1'b1; store_wburst_counter = 32'd1; wburst_counter = 32'dx; end // Read fifth 32 bits of data, store fourth 32 bits of data
                            4'd5: begin inc_write_counter = 1'b1; write_to_mem = 1'b1; store_write_data = 1'b1; store_wburst_counter = 32'd0; wburst_counter = 32'd1; end // Read sixth 32 bits of data, store fifth 32 bits of data, write second 64 bits to memory
                            4'd6: begin inc_write_counter = 1'b1; write_to_mem = 1'b0; store_write_data = 1'b1; store_wburst_counter = 32'd1; wburst_counter = 32'dx; end // Read seventh 32 bits of data, store sixth 32 bits of data
                            4'd7: begin inc_write_counter = 1'b1; write_to_mem = 1'b1; store_write_data = 1'b1; store_wburst_counter = 32'd0; wburst_counter = 32'd2; end // Read eighth 32 bits of data, store seventh 32 bits of data, write third 64 bits to memory
                        endcase
                    end else begin
                        itf.r_en_CPU_to_FPGA_FIFO = 1'b0;
                        case(write_counter)
                            4'd8: begin inc_write_counter = 1'b1; write_to_mem = 1'b0; store_write_data = 1'b1; store_wburst_counter = 32'd1; wburst_counter = 32'dx; end // Store eighth 32 bits of data
                            4'd9: begin inc_write_counter = 1'b1; write_to_mem = 1'b1; store_write_data = 1'b0; store_wburst_counter = 32'd0; wburst_counter = 32'd3; end // Write fourth 64 bits to memory
                        endcase
                    end
                end else begin
                    // Respond to CPU so it can continue
                    itf.w_en_FPGA_to_CPU_FIFO = 1'b1;
                    fpga_resp = 1'b1;
                    next_state = FPGA_IDLE;
                end
            end
            default: begin
                itf.r_en_CPU_to_FPGA_FIFO = 1'b0;
                itf.w_en_FPGA_to_CPU_FIFO = 1'b0;
                store_address = 1'b0;
                store_write_data = 1'b0;
                read_from_mem = 1'b0;
                write_to_mem = 1'b0;
                rburst_counter = 'x;
                wburst_counter = 'x;
                store_wburst_counter = 'x;
                sub_rburst_counter = 'x;
                fpga_resp = 1'b0;
                inc_write_counter = 1'b0;
                clear_address = 1'b0;
                clear_data = 1'b0;
                next_state = state;
            end
        endcase
    end


    always_ff @(posedge itf.fpga_clk) begin : memory_interface

        if(read_from_mem) begin
            // $display("Read - Address: 0x%x, Data: 0x%x", (addra + (32'd8 *rburst_counter)) + 4*sub_rburst_counter, internal_memory_array[(addra + (32'd8 *rburst_counter)) / 32'd8][32*sub_rburst_counter +: 32]);
            // if($isunknown(internal_memory_array[(addra + (32'd8 *rburst_counter)) / 32'd8][32*sub_rburst_counter +: 32])) $display("Read data is invalid");
            itf.data_in_FPGA_to_CPU_FIFO <= internal_memory_array[(addra + (32'd8 *rburst_counter)) / 32'd8][32*sub_rburst_counter +: 32];
        end else if(fpga_resp)begin
            itf.data_in_FPGA_to_CPU_FIFO <= {36{1'b1}};
        end else begin
            itf.data_in_FPGA_to_CPU_FIFO <= 'x;
        end

        if(write_to_mem) begin
            internal_memory_array[(addra + (32'd8 *wburst_counter)) / 32'd8] <= dina;
            // if($isunknown(dina)) $display("Data is invalid.");
            // $display("Write - Address: 0x%x, Data: 0x%x", (addra + (32'd8 *wburst_counter)), dina);
        end 
    end



    // typedef enum logic [4:0] {  
    //     idle,
    //     read_address,
    //     read_data,
    //     read_data_1,
    //     read_data_2,
    //     read_data_3,
    //     read_data_4,
    //     read_data_5,
    //     read_data_6,
    //     read_data_7,
    //     read_data_8,
    //     read_data_from_memory,
    //     read_data_from_memory2,
    //     read_data_from_memory3,
    //     read_data_from_memory4,
    //     read_data_from_memory5,
    //     read_data_from_memory6,
    //     read_data_from_memory7,
    //     read_data_from_memory8,
    //     respond
    // } state_t;

    // state_t state, next_state;

    // always_ff @(posedge itf.fpga_clk) begin
    //     if(itf.rst) begin
    //         state <= idle;
    //     end else begin
    //         state <= next_state;
    //     end 
    // end

    // always_comb begin
    //     store_address = 1'b0;
    //     clear_address = 1'b0;
    //     store_data = 1'b0;
    //     store_data_1 = 1'b0;
    //     clear_data = 1'b0;
    //     enable_memory = 1'b0;
    //     itf.resp_m_to_c = 1'b0;
    //     rburst_counter = 32'd0;
    //     wburst_counter = 32'd0;
    //     sub_rburst_counter = 1'b0;
    //     unique case(state)
    //         idle: begin
    //             clear_address = 1'b1;
    //             clear_data = 1'b1;
    //             if(itf.read_en_c_to_m | itf.write_en_c_to_m) begin
    //                 next_state = read_address;
    //             end else begin
    //                 next_state = idle;
    //             end
    //         end
    //         read_address: begin
    //             if(itf.address_on_c_to_m) begin
    //                 // Store Address
    //                 store_address = 1'b1;
    //                 itf.resp_m_to_c = 1'b1;
    //                 if(itf.write_en_c_to_m) begin
    //                     next_state = read_data;
    //                 end else begin
    //                     next_state = read_data_from_memory; // Move to perform a read operation and respond
    //                 end
    //             end else begin
    //                 next_state = read_address; // Maintain state until address is on bus
    //             end
    //         end
    //         read_data: begin
    //             if(itf.data_on_c_to_m) begin
    //                 // Store Data
    //                 // store_data = 1'b1;
    //                 itf.resp_m_to_c = 1'b1;
    //                 next_state = read_data_1;
    //             end else begin
    //                 next_state = read_data; // Maintain state until data is on bus
    //             end
    //         end
    //         read_data_1: begin
    //             if(itf.data_on_c_to_m) begin
    //                 // Store Data
    //                 // enable_memory = 1'b1;
    //                 store_data = 1'b1;
    //                 itf.resp_m_to_c = 1'b1;
    //                 next_state = read_data_2;
    //             end else begin
    //                 next_state = read_data_1;
    //             end
    //         end
    //         read_data_2: begin
    //             if(itf.data_on_c_to_m) begin
    //                 // Store Data
    //                 store_data_1 = 1'b1;
    //                 itf.resp_m_to_c = 1'b1;
    //                 next_state = read_data_3;
    //             end else begin
    //                 next_state = read_data_2; // Maintain state until data is on bus
    //             end
    //         end
    //         read_data_3: begin
    //             if(itf.data_on_c_to_m) begin
    //                 // Store Data
    //                 enable_memory = 1'b1;
    //                 wburst_counter = 32'd0;
    //                 store_data = 1'b1;
    //                 itf.resp_m_to_c = 1'b1;
    //                 next_state = read_data_4;
    //             end else begin
    //                 next_state = read_data_3;
    //             end
    //         end
    //         read_data_4: begin
    //             if(itf.data_on_c_to_m) begin
    //                 // Store Data
    //                 store_data_1 = 1'b1;
    //                 itf.resp_m_to_c = 1'b1;
    //                 next_state = read_data_5;
    //             end else begin
    //                 next_state = read_data_4; // Maintain state until data is on bus
    //             end
    //         end
    //         read_data_5: begin
    //             if(itf.data_on_c_to_m) begin
    //                 // Store Data
    //                 enable_memory = 1'b1;
    //                 wburst_counter = 32'd1;
    //                 store_data = 1'b1;
    //                 itf.resp_m_to_c = 1'b1;
    //                 next_state = read_data_6;
    //             end else begin
    //                 next_state = read_data_5;
    //             end
    //         end
    //         read_data_6: begin
    //             if(itf.data_on_c_to_m) begin
    //                 // Store Data
    //                 store_data_1 = 1'b1;
    //                 itf.resp_m_to_c = 1'b1;
    //                 next_state = read_data_7;
    //             end else begin
    //                 next_state = read_data_6; // Maintain state until data is on bus
    //             end
    //         end
    //         read_data_7: begin
    //             if(itf.data_on_c_to_m) begin
    //                 // Store Data
    //                 enable_memory = 1'b1;
    //                 wburst_counter = 32'd2;
    //                 store_data = 1'b1;
    //                 itf.resp_m_to_c = 1'b1;
    //                 next_state = read_data_8;
    //             end else begin
    //                 next_state = read_data_7;
    //             end
    //         end
    //         read_data_8: begin
    //             if(itf.data_on_c_to_m) begin
    //                 // Store Data
    //                 store_data_1 = 1'b1;
    //                 itf.resp_m_to_c = 1'b1;
    //                 next_state = respond;
    //             end else begin
    //                 next_state = read_data_1;
    //             end
    //         end
    //         read_data_from_memory: begin
    //             enable_memory = 1'b1;
    //             rburst_counter = 32'd0;
    //             sub_rburst_counter = 1'b0;
    //             next_state = read_data_from_memory2;
    //         end
    //         read_data_from_memory2: begin
    //             enable_memory = 1'b1;
    //             itf.resp_m_to_c = 1'b1;
    //             rburst_counter = 32'd0;
    //             sub_rburst_counter = 1'b1;
    //             next_state = read_data_from_memory3;
    //         end
    //         read_data_from_memory3: begin
    //             enable_memory = 1'b1;
    //             itf.resp_m_to_c = 1'b1;
    //             rburst_counter = 32'd1;
    //             sub_rburst_counter = 1'b0;
    //             next_state = read_data_from_memory4;
    //         end
    //         read_data_from_memory4: begin
    //             enable_memory = 1'b1;
    //             itf.resp_m_to_c = 1'b1;
    //             rburst_counter = 32'd1;
    //             sub_rburst_counter = 1'b1;
    //             next_state = read_data_from_memory5;
    //         end

    //         read_data_from_memory5: begin
    //             enable_memory = 1'b1;
    //             itf.resp_m_to_c = 1'b1;
    //             rburst_counter = 32'd2;
    //             sub_rburst_counter = 1'b0;
    //             next_state = read_data_from_memory6;
    //         end
    //         read_data_from_memory6: begin
    //             enable_memory = 1'b1;
    //             itf.resp_m_to_c = 1'b1;
    //             rburst_counter = 32'd2;
    //             sub_rburst_counter = 1'b1;
    //             next_state = read_data_from_memory7;
    //         end

    //         read_data_from_memory7: begin
    //             enable_memory = 1'b1;
    //             itf.resp_m_to_c = 1'b1;
    //             rburst_counter = 32'd3;
    //             sub_rburst_counter = 1'b0;
    //             next_state = read_data_from_memory8;
    //         end
    //         read_data_from_memory8: begin
    //             enable_memory = 1'b1;
    //             itf.resp_m_to_c = 1'b1;
    //             rburst_counter = 32'd3;
    //             sub_rburst_counter = 1'b1;
    //             next_state = respond;
    //         end

    //         respond: begin
    //             enable_memory = 1'b1;
    //             wburst_counter = 32'd3;
    //             itf.resp_m_to_c = 1'b1;
    //             next_state = idle;
    //         end
    //         default: begin
    //             clear_address = 1'b0;
    //             store_address = 1'b0;
    //             clear_data = 1'b0;
    //             store_data = 1'b0;
    //             itf.resp_m_to_c  = 1'b0;
    //             enable_memory = 1'b0;
    //             next_state = state;
    //         end
    //     endcase
    // end

    // always_ff @(posedge itf.fpga_clk) begin
    //     if(store_address) begin
    //         addra <= itf.address_data_bus_c_to_m;
    //     end else if(clear_address) begin
    //         addra <= 'x;
    //     end

    //     if(store_data) begin
    //         dina[31:0] <= itf.address_data_bus_c_to_m;
    //     end else if(store_data_1) begin
    //         dina[63:32] <= itf.address_data_bus_c_to_m;
    //     end else if(clear_data) begin
    //         dina <= 'x;
    //     end
    // end

    // always_ff @(posedge itf.fpga_clk) begin : memory_interface
    //     if(enable_memory) begin
    //         if(itf.write_en_c_to_m) begin
    //             internal_memory_array[(addra + (32'd8 *wburst_counter)) / 32'd8] <= dina;
    //             if($isunknown(dina)) $display("Data is invalid.");
    //             $display("Write - Address: 0x%x, Data: 0x%x", (addra + (32'd8 *wburst_counter)), dina);
    //         end else if(itf.read_en_c_to_m)begin
    //             $display("Read - Address: 0x%x, Data: 0x%x", (addra + (32'd8 *rburst_counter)) + 4*sub_rburst_counter, internal_memory_array[(addra + (32'd8 *rburst_counter)) / 32'd8][32*sub_rburst_counter +: 32]);
    //             itf.address_data_bus_m_to_c <= internal_memory_array[(addra + (32'd8 *rburst_counter)) / 32'd8][32*sub_rburst_counter +: 32];
    //         end else begin
    //             itf.address_data_bus_m_to_c <= 'x;
    //         end
    //     end else begin
    //         itf.address_data_bus_m_to_c <= 'x;
    //     end
    // end


endmodule