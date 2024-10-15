module fpga_mem_controller(
    input   logic clk,
    input   logic fpga_clk,
    input   logic rst,

    // Caches -> Controller
    input logic   [31:0]      bmem_addr,
    input logic               bmem_read,
    input logic               bmem_write,
    input logic   [63:0]      bmem_wdata,
    
    // Controller -> Caches
    output logic               bmem_ready,
    output logic   [31:0]      bmem_raddr,
    output logic   [63:0]      bmem_rdata,
    output logic               bmem_rvalid,
    output logic               wburst_counter,

    // Memory -> Controller
    input logic r_en_CPU_to_FPGA_FIFO,                  // FPGA Reads from the CPU to FPGA FIFO
    input logic w_en_FPGA_to_CPU_FIFO,                  // FPGA Writes to FPGA to CPU FIFO

    // Controller -> Memory
    output logic empty_CPU_to_FPGA_FIFO,                // FPGA Uses to determine if CPU has written data
    output logic full_FPGA_to_CPU_FIFO,                 // FPGA Uses to determine if it can write to the FPGA to CPU FIFO

    // Controller <-> Memory
    inout wire [32:0] address_data_bus                  // 32 Bit bi-directional bus + 2 Bits for Metadata, Driven by FPGA to return read memory, Driven by CPU to provide data to be written
);

    // Asynchronous FIFO from CPU to FPGA

    // CPU Signals
    logic [32:0] data_in_CPU_to_FPGA_FIFO; // Drives
    logic        w_en_CPU_to_FPGA_FIFO; // Drives
    logic        full_CPU_to_FPGA_FIFO; // Uses

    // FPGA Signals
    logic [32:0] data_out_CPU_to_FPGA_FIFO; // Uses
    // logic        r_en_CPU_to_FPGA_FIFO; // Drives
    // logic        empty_CPU_to_FPGA_FIFO; // Uses

    // async_fifo CPU_to_FPGA_FIFO(
    //     .data_in(data_in_CPU_to_FPGA_FIFO),
    //     .w_en(w_en_CPU_to_FPGA_FIFO),
    //     .w_clk(clk), // 800 MHz
    //     .w_rst(rst), // Global Reset
    //     .full(full_CPU_to_FPGA_FIFO),

    //     .data_out(data_out_CPU_to_FPGA_FIFO),
    //     .r_en(r_en_CPU_to_FPGA_FIFO),
    //     .r_clk(fpga_clk), // 100 MHz
    //     .r_rst(rst), // Global Reset
    //     .empty(empty_CPU_to_FPGA_FIFO)
    // );



    logic        clk_push_CPU_to_FPGA_FIFO;     // CPU Clock
    logic        clk_pop_CPU_to_FPGA_FIFO;      // FPGA Clock
    logic        rst_n_CPU_to_FPGA_FIFO;        // Active Low, Global Reset
    logic        push_req_n_CPU_to_FPGA_FIFO;   // Active Low, Push Request, Driven by CPU
    logic        flush_n_CPU_to_FPGA_FIFO;      // Active Low, Not used since d_in_width == d_out_width
    logic        pop_req_n_CPU_to_FPGA_FIFO;    // Active Low, Pop Request, Driven by FPGA
    logic [32:0] data_in_CPU_to_FPGA_FIFO_IP;   // Input data, Driven by CPU

    logic        push_empty_CPU_to_FPGA_FIFO;   // FIFO Empty, Used by CPU, Active High
    logic        push_ae_CPU_to_FPGA_FIFO;      // FIFO Almost Empty, Used by CPU, Active High
    logic        push_hf_CPU_to_FPGA_FIFO;      // FIFO Half Full, Used by CPU, Active High
    logic        push_af_CPU_to_FPGA_FIFO;      // FIFO Almost Full, Used by CPU, Active High
    logic        push_full_CPU_to_FPGA_FIFO;    // FIFO RAM Full, Used by CPU, Without input buffer
    logic        ram_full_CPU_to_FPGA_FIFO;     // FIFO RAM Full, Not used since d_in_width == d_out_width, Used by CPU, With input buffer
    logic        part_wd_CPU_to_FPGA_FIFO;      // Partial Word Accumulated, Not used since d_in_width == d_out_width, Used by CPU
    logic        push_error_CPU_to_FPGA_FIFO;   // FIFO Push Error (overrun), Used by CPU
    logic        pop_empty_CPU_to_FPGA_FIFO;    // FIFO Empty, Used by FPGA
    logic        pop_ae_CPU_to_FPGA_FIFO;       // FIFO Almost Empty, Used by FPGA
    logic        pop_hf_CPU_to_FPGA_FIFO;       // FIFO Half Full, Used by FPGA
    logic        pop_af_CPU_to_FPGA_FIFO;       // FIFO Almost Full, Used by FPGA
    logic        pop_full_CPU_to_FPGA_FIFO;     // FIFO Full, Used by FPGA
    logic        pop_error_CPU_to_FPGA_FIFO;    // FIFO Pop Error, Used by FPGA
    logic [32:0] data_out_CPU_to_FPGA_FIFO_IP;  // Output data, Used by FPGA
    logic [32:0] data_out_CPU_to_FPGA_FIFO_IP_LATCHED;  // Latched Output data, Used by FPGA

    // Assign the input signals to the CPU to FPGA FIFO
    assign clk_push_CPU_to_FPGA_FIFO = clk;
    assign clk_pop_CPU_to_FPGA_FIFO = fpga_clk;
    assign rst_n_CPU_to_FPGA_FIFO = !rst;
    assign push_req_n_CPU_to_FPGA_FIFO = !w_en_CPU_to_FPGA_FIFO;
    assign flush_n_CPU_to_FPGA_FIFO = 1'b1;
    assign pop_req_n_CPU_to_FPGA_FIFO = !r_en_CPU_to_FPGA_FIFO;
    assign data_in_CPU_to_FPGA_FIFO_IP = data_in_CPU_to_FPGA_FIFO;

    // Utilize the output signals from the CPU to FPGA FIFO
    always_ff @(posedge fpga_clk) begin
        if(rst) begin
            data_out_CPU_to_FPGA_FIFO_IP_LATCHED <= 'x;
        end else begin
            data_out_CPU_to_FPGA_FIFO_IP_LATCHED <= data_out_CPU_to_FPGA_FIFO_IP; // Latched output for the data bus
        end
    end
    assign full_CPU_to_FPGA_FIFO = push_full_CPU_to_FPGA_FIFO; // Used on the CPU
    assign empty_CPU_to_FPGA_FIFO = pop_empty_CPU_to_FPGA_FIFO; // Used on the FPGA

    // Drive bus from the CPU side
    assign address_data_bus = w_en_FPGA_to_CPU_FIFO ? 'z : data_out_CPU_to_FPGA_FIFO_IP_LATCHED;

    DW_asymfifo_s2_sf #(
        .data_in_width(33),
        .data_out_width(33),
        .depth(32)
    ) CPU_to_FPGA_FIFO_test (
        .clk_push(clk_push_CPU_to_FPGA_FIFO),
        .clk_pop(clk_pop_CPU_to_FPGA_FIFO),
        .rst_n(rst_n_CPU_to_FPGA_FIFO),
        .push_req_n(push_req_n_CPU_to_FPGA_FIFO),
        .flush_n(flush_n_CPU_to_FPGA_FIFO),
        .pop_req_n(pop_req_n_CPU_to_FPGA_FIFO),
        .data_in(data_in_CPU_to_FPGA_FIFO_IP),

        .push_empty(push_empty_CPU_to_FPGA_FIFO),
        .push_ae(push_ae_CPU_to_FPGA_FIFO),
        .push_hf(push_hf_CPU_to_FPGA_FIFO),
        .push_af(push_af_CPU_to_FPGA_FIFO),
        .push_full(push_full_CPU_to_FPGA_FIFO), // Used
        .ram_full(ram_full_CPU_to_FPGA_FIFO),
        .part_wd(part_wd_CPU_to_FPGA_FIFO),
        .push_error(push_error_CPU_to_FPGA_FIFO),
        .pop_empty(pop_empty_CPU_to_FPGA_FIFO), // Used
        .pop_ae(pop_ae_CPU_to_FPGA_FIFO),
        .pop_hf(pop_hf_CPU_to_FPGA_FIFO),
        .pop_af(pop_af_CPU_to_FPGA_FIFO),
        .pop_full(pop_full_CPU_to_FPGA_FIFO),
        .pop_error(pop_error_CPU_to_FPGA_FIFO),
        .data_out(data_out_CPU_to_FPGA_FIFO_IP) // Used
    );



    // Asynchronous FIFO from FPGA to CPU

    // FPGA Signals
    // logic [35:0] data_in_FPGA_to_CPU_FIFO; // Driven
    // logic        w_en_FPGA_to_CPU_FIFO; // Driven
    // logic        full_FPGA_to_CPU_FIFO; // Uses

    // CPU Signals
    logic [32:0] data_out_FPGA_to_CPU_FIFO; // Uses
    logic        r_en_FPGA_to_CPU_FIFO; // Driven
    logic        empty_FPGA_to_CPU_FIFO; // Uses
    
    // async_fifo FPGA_to_CPU_FIFO(
    //     .data_in(address_data_bus),
    //     .w_en(w_en_FPGA_to_CPU_FIFO),
    //     .w_clk(fpga_clk), // 100 MHz
    //     .w_rst(rst), // Global Reset
    //     .full(full_FPGA_to_CPU_FIFO),

    //     .data_out(data_out_FPGA_to_CPU_FIFO),
    //     .r_en(r_en_FPGA_to_CPU_FIFO),
    //     .r_clk(clk), // 800 MHz
    //     .r_rst(rst), // Global Reset
    //     .empty(empty_FPGA_to_CPU_FIFO)
    // );

    logic        clk_push_FPGA_to_CPU_FIFO;     // FPGA Clock
    logic        clk_pop_FPGA_to_CPU_FIFO;      // CPU Clock
    logic        rst_n_FPGA_to_CPU_FIFO;        // Active Low, Global Reset
    logic        push_req_n_FPGA_to_CPU_FIFO;   // Active Low, Push Request, Driven by FPGA
    logic        flush_n_FPGA_to_CPU_FIFO;      // Active Low, Not used since d_in_width == d_out_width
    logic        pop_req_n_FPGA_to_CPU_FIFO;    // Active Low, Pop Request, Driven by the CPU
    logic [32:0] data_in_FPGA_to_CPU_FIFO_IP;   // Input data, Driven by the FPGA

    logic        push_empty_FPGA_to_CPU_FIFO;   // FIFO Empty, Used by FPGA, Active High
    logic        push_ae_FPGA_to_CPU_FIFO;      // FIFO Almost Empty, Used by FPGA, Active High
    logic        push_hf_FPGA_to_CPU_FIFO;      // FIFO Half Empty, Used by FPGA, Active High
    logic        push_af_FPGA_to_CPU_FIFO;      // FIFO Almost Full, Used by FPGA, Active High
    logic        push_full_FPGA_to_CPU_FIFO;    // FIFO RAM Full, Used by FPGA, Without input buffer
    logic        ram_full_FPGA_to_CPU_FIFO;     // FIFO RAM Full, Not used since d_in_width == d_out_width, Used by FPGA, With input buffer
    logic        part_wd_FPGA_to_CPU_FIFO;      // Partial Word Accumulated, Not used since d_in_width == d_out_width, Used by FPGA
    logic        push_error_FPGA_to_CPU_FIFO;   // FIFO Push Error (overrun), Used by FPGA
    logic        pop_empty_FPGA_to_CPU_FIFO;    // FIFO Empty, Used by CPU
    logic        pop_ae_FPGA_to_CPU_FIFO;       // FIFO Almost Empty, Used by CPU
    logic        pop_hf_FPGA_to_CPU_FIFO;       // FIFO Half Full, Used by CPU
    logic        pop_af_FPGA_to_CPU_FIFO;       // FIFO Almost Full, Used by CPU
    logic        pop_full_FPGA_to_CPU_FIFO;     // FIFO Full, Used by CPU
    logic        pop_error_FPGA_to_CPU_FIFO;    // FIFO Pop Error, Used by CPU
    logic [32:0] data_out_FPGA_to_CPU_FIFO_IP;  // Output data, Used by CPU
    logic [32:0] data_out_FPGA_to_CPU_FIFO_IP_LATCHED;  // Output data, Used by CPU

    // Assign the input signals to the FPGA to CPU FIFO
    assign clk_push_FPGA_to_CPU_FIFO = fpga_clk;
    assign clk_pop_FPGA_to_CPU_FIFO = clk;
    assign rst_n_FPGA_to_CPU_FIFO = !rst;
    assign push_req_n_FPGA_to_CPU_FIFO = !w_en_FPGA_to_CPU_FIFO;
    assign flush_n_FPGA_to_CPU_FIFO = 1'b1;
    assign pop_req_n_FPGA_to_CPU_FIFO = !r_en_FPGA_to_CPU_FIFO;
    assign data_in_FPGA_to_CPU_FIFO_IP = address_data_bus;

    // Utilize the output signals from the FPGA to CPU FIFO
    always_ff @(posedge clk) begin
        if(rst) begin
            data_out_FPGA_to_CPU_FIFO_IP_LATCHED <= 'x;
        end else begin
            if(r_en_FPGA_to_CPU_FIFO) data_out_FPGA_to_CPU_FIFO_IP_LATCHED <= data_out_FPGA_to_CPU_FIFO_IP;
        end
    end

    assign data_out_FPGA_to_CPU_FIFO = data_out_FPGA_to_CPU_FIFO_IP_LATCHED; // Used on the CPU
    assign empty_FPGA_to_CPU_FIFO = pop_empty_FPGA_to_CPU_FIFO; // Used on the CPU
    assign full_FPGA_to_CPU_FIFO = push_full_FPGA_to_CPU_FIFO; // Used on the FPGA

    DW_asymfifo_s2_sf #(
        .data_in_width(33),
        .data_out_width(33),
        .depth(32)
    ) FPGA_TO_CPU_FIFO_test(
        .clk_push(clk_push_FPGA_to_CPU_FIFO), // Driven by FPGA
        .clk_pop(clk_pop_FPGA_to_CPU_FIFO), // Driven by CPU
        .rst_n(rst_n_FPGA_to_CPU_FIFO), // Global Reset
        .push_req_n(push_req_n_FPGA_to_CPU_FIFO), // Driven by FPGA 
        .flush_n(flush_n_FPGA_to_CPU_FIFO),
        .pop_req_n(pop_req_n_FPGA_to_CPU_FIFO), // Driven by CPU
        .data_in(data_in_FPGA_to_CPU_FIFO_IP),

        .push_empty(push_empty_FPGA_to_CPU_FIFO),
        .push_ae(push_ae_FPGA_to_CPU_FIFO),
        .push_hf(push_hf_FPGA_to_CPU_FIFO),
        .push_af(push_af_FPGA_to_CPU_FIFO),
        .push_full(push_full_FPGA_to_CPU_FIFO), // Used
        .ram_full(ram_full_FPGA_to_CPU_FIFO),
        .part_wd(part_wd_FPGA_to_CPU_FIFO),
        .push_error(push_error_FPGA_to_CPU_FIFO),
        .pop_empty(pop_empty_FPGA_to_CPU_FIFO), // Used
        .pop_ae(pop_ae_FPGA_to_CPU_FIFO),
        .pop_hf(pop_hf_FPGA_to_CPU_FIFO),
        .pop_af(pop_af_FPGA_to_CPU_FIFO),
        .pop_full(pop_full_FPGA_to_CPU_FIFO),
        .pop_error(pop_error_FPGA_to_CPU_FIFO),
        .data_out(data_out_FPGA_to_CPU_FIFO_IP) // Used
    );

    enum logic [4:0] {
        CPU_IDLE,
        // Read Operation
        CPU_SEND_RADDR,
        CPU_READ_DATA,
        // Write Operation
        CPU_SEND_WADDR,
        CPU_WRITE_DATA
    } state, next_state;

    always_ff @(posedge clk) begin : update_state
        if(rst) begin
            state <= CPU_IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Control Signals
    logic [3:0] read_counter; // 0 -> 7 + 1 overflow bit
    logic inc_read_counter;
    logic [3:0] write_counter; // 0 -> 7 + 1 overflow bit
    logic inc_write_counter;
    logic store_bmem_address;
    logic [31:0] latched_bmem_addr;
    logic rburst_counter;
    logic store_fpga_mem;

    always_ff @(posedge clk) begin
        if(rst) begin
            read_counter <= '0;
            write_counter <= '0;
            latched_bmem_addr <= 'x;
            bmem_rdata <= 'x;
        end else begin
            if(inc_read_counter) read_counter <= read_counter + 4'd1;
            if(read_counter == 4'd10) read_counter <= '0;

            if(inc_write_counter) write_counter <= write_counter + 4'd1;
            if(write_counter == 4'd10) write_counter <= '0;

            if(store_bmem_address) latched_bmem_addr <= bmem_addr;

            if(store_fpga_mem) begin
                if(rburst_counter) bmem_rdata[63:32] <= data_out_FPGA_to_CPU_FIFO[31:0];
                else bmem_rdata[31:0] <= data_out_FPGA_to_CPU_FIFO[31:0];
            end

        end
    end


    always_comb begin : next_state_logic
        w_en_CPU_to_FPGA_FIFO = 1'b0;
        r_en_FPGA_to_CPU_FIFO = 1'b0;
        bmem_ready = 1'b0;
        bmem_rvalid = 1'b0;
        store_fpga_mem = 1'b0;
        store_bmem_address = 1'b0;
        rburst_counter = 'x;
        bmem_raddr = 'x;
        inc_read_counter = 1'b0;
        inc_write_counter = 1'b0;
        data_in_CPU_to_FPGA_FIFO = 'x;
        wburst_counter = 1'b0;
        next_state = state;
        unique case(state)
            CPU_IDLE: begin // Wait for a read or write operation from the CPU
                bmem_ready = 1'b1; // Allow for memory to be accessed
                if(bmem_read) begin
                    store_bmem_address = 1'b1; // Store the memory address
                    next_state = CPU_SEND_RADDR;
                end else if(bmem_write) begin
                    store_bmem_address = 1'b1; // Store the memory address
                    next_state = CPU_SEND_WADDR;
                end else begin
                    next_state = CPU_IDLE;
                end
            end
            CPU_SEND_RADDR: begin // Deliver the read address to the FPGA over the CPU_to_FPGA_FIFO
                w_en_CPU_to_FPGA_FIFO = 1'b1; // Enable FIFO memory
                data_in_CPU_to_FPGA_FIFO = {1'b0, // Write Enable - OFF
                                            latched_bmem_addr};
                next_state = CPU_READ_DATA;
            end
            CPU_READ_DATA: begin // Wait for the FPGA to deliver the data over the FPGA_to_CPU_FIFO
                bmem_raddr = latched_bmem_addr;
                if(read_counter <= 4'd9) begin
                    next_state = CPU_READ_DATA;
                    if(!empty_FPGA_to_CPU_FIFO) begin
                        // Read the data that the FPGA writes back to the CPU
                        case(read_counter)
                            4'd0: begin inc_read_counter = 1'b1; r_en_FPGA_to_CPU_FIFO = 1'b1; rburst_counter = 1'bx; bmem_rvalid = 1'b0; store_fpga_mem = 1'b0; end   // Read first 32 bits
                            4'd1: begin inc_read_counter = 1'b1; r_en_FPGA_to_CPU_FIFO = 1'b1; rburst_counter = 1'b0; bmem_rvalid = 1'b0; store_fpga_mem = 1'b1; end   // Read second 32 bits, store first 32 bits
                            4'd2: begin inc_read_counter = 1'b1; r_en_FPGA_to_CPU_FIFO = 1'b1; rburst_counter = 1'b1; bmem_rvalid = 1'b0; store_fpga_mem = 1'b1; end   // Read third 32 bits, store second 32 bits
                            4'd3: begin inc_read_counter = 1'b1; r_en_FPGA_to_CPU_FIFO = 1'b1; rburst_counter = 1'b0; bmem_rvalid = 1'b1; store_fpga_mem = 1'b1; end   // Read fourth 32 bits, store third 32 bits, validate first 64 bits
                            4'd4: begin inc_read_counter = 1'b1; r_en_FPGA_to_CPU_FIFO = 1'b1; rburst_counter = 1'b1; bmem_rvalid = 1'b0; store_fpga_mem = 1'b1; end   // Read fifth 32 bits, store fourth 32 bits
                            4'd5: begin inc_read_counter = 1'b1; r_en_FPGA_to_CPU_FIFO = 1'b1; rburst_counter = 1'b0; bmem_rvalid = 1'b1; store_fpga_mem = 1'b1; end   // Read sixth 32 bits, store fifth 32 bits, validate second 64 bits
                            4'd6: begin inc_read_counter = 1'b1; r_en_FPGA_to_CPU_FIFO = 1'b1; rburst_counter = 1'b1; bmem_rvalid = 1'b0; store_fpga_mem = 1'b1; end   // Read seventh 32 bits, store sixth 32 btis
                            4'd7: begin inc_read_counter = 1'b1; r_en_FPGA_to_CPU_FIFO = 1'b1; rburst_counter = 1'b0; bmem_rvalid = 1'b1; store_fpga_mem = 1'b1; end   // Read eighth 32 bits, store seventh 32 bits, validate third 64 bits
                        endcase
                    end else begin
                        case(read_counter)
                            4'd8: begin inc_read_counter = 1'b1; r_en_FPGA_to_CPU_FIFO = 1'b0; rburst_counter = 1'b1; bmem_rvalid = 1'b0; store_fpga_mem = 1'b1; end   // Store eighth 32 bits 
                            4'd9: begin inc_read_counter = 1'b1; r_en_FPGA_to_CPU_FIFO = 1'b0; rburst_counter = 1'bx; bmem_rvalid = 1'b1; store_fpga_mem = 1'b0; end   // Validate eighth 32 bits
                        endcase
                    end
                end else begin
                    next_state = CPU_IDLE;
                end
            end
            CPU_SEND_WADDR: begin // Deliver the write address to the FPGA over the CPU_to_FPGA_FIFO
                w_en_CPU_to_FPGA_FIFO = 1'b1; // Enable FIFO memory
                data_in_CPU_to_FPGA_FIFO = {1'b1, // Write Enable - ON
                                            latched_bmem_addr};
                next_state = CPU_WRITE_DATA;
            end
            CPU_WRITE_DATA: begin // Deliver the write data to the FPGA over the CPU_to_FPGA_FIFO and wait for a response from FPGA that it wrote the data
                if(write_counter <= 4'd7) begin
                    next_state = CPU_WRITE_DATA;
                    if(!full_CPU_to_FPGA_FIFO) begin
                        w_en_CPU_to_FPGA_FIFO = 1'b1; // Enable FIFO memory
                        inc_write_counter = 1'b1; // Update the write counter
                        case(write_counter)
                            4'd0, 4'd2, 4'd4, 4'd6: begin
                                wburst_counter = 1'b0;
                                data_in_CPU_to_FPGA_FIFO = {1'b1, // Write Enable - ON
                                                            bmem_wdata[31:0]};
                            end
                            4'd1, 4'd3, 4'd5, 4'd7: begin
                                wburst_counter = 1'b1;
                                data_in_CPU_to_FPGA_FIFO = {1'b1, // Write Enable - ON
                                                            bmem_wdata[63:32]};
                            end
                        endcase 
                    end
                end else begin
                    if(write_counter == 4'd8) begin
                        // We have written all of the data now we wait for FPGA to respond
                        next_state = CPU_WRITE_DATA;
                        if(!empty_FPGA_to_CPU_FIFO) begin
                            // We can write anything onto the FIFO and this can be interpreted as a response from the FPGA
                            inc_write_counter = 1'b1;
                            r_en_FPGA_to_CPU_FIFO = 1'b1; // Make sure to get it off of the FIFO
                            bmem_ready = 1'b1;
                        end
                    end else begin
                        if(write_counter == 4'd9) begin
                            if(bmem_write) begin
                                next_state = CPU_WRITE_DATA;
                            end else begin
                                inc_write_counter = 1'b1;
                                next_state = CPU_IDLE;
                            end
                        end
                    end
                end
            end
            default: begin
                w_en_CPU_to_FPGA_FIFO = 1'b0;
                r_en_FPGA_to_CPU_FIFO = 1'b0;
                bmem_ready = 1'b0;
                bmem_rvalid = 1'b0;
                store_fpga_mem = 1'b0;
                store_bmem_address = 1'b0;
                rburst_counter = 'x;
                bmem_raddr = 'x;
                inc_read_counter = 1'b0;
                inc_write_counter = 1'b0;
                data_in_CPU_to_FPGA_FIFO = 'x;
                wburst_counter = 1'b0;
                next_state = state;
            end
        endcase
    end
    
endmodule