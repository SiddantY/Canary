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
    input logic [31:0] address_data_bus_m_to_c,
    input logic resp_m_to_c,
    input logic r_en_CPU_to_FPGA_FIFO,
    input logic w_en_FPGA_to_CPU_FIFO,
    input logic [35:0] data_in_FPGA_to_CPU_FIFO,

    // Controller -> Memory
    output logic [31:0] address_data_bus_c_to_m,
    output logic address_on_c_to_m,
    output logic data_on_c_to_m,
    output logic read_en_c_to_m,
    output logic write_en_c_to_m,
    output logic empty_CPU_to_FPGA_FIFO,
    output logic full_FPGA_to_CPU_FIFO
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

    // Asynchronous FIFO from CPU to FPGA

    // CPU Signals
    logic [35:0] data_in_CPU_to_FPGA_FIFO; // Drives
    logic        w_en_CPU_to_FPGA_FIFO; // Drives
    logic        full_CPU_to_FPGA_FIFO; // Uses

    // FPGA Signals
    logic [35:0] data_out_CPU_to_FPGA_FIFO; // Uses
    // logic        r_en_CPU_to_FPGA_FIFO; // Drives
    // logic        empty_CPU_to_FPGA_FIFO; // Uses

    async_fifo CPU_to_FPGA_FIFO(
        .data_in(data_in_CPU_to_FPGA_FIFO),
        .w_en(w_en_CPU_to_FPGA_FIFO),
        .w_clk(clk), // 800 MHz
        .w_rst(rst), // Global Reset
        .full(full_CPU_to_FPGA_FIFO),

        .data_out(data_out_CPU_to_FPGA_FIFO),
        .r_en(r_en_CPU_to_FPGA_FIFO),
        .r_clk(fpga_clk), // 100 MHz
        .r_rst(rst), // Global Reset
        .empty(empty_CPU_to_FPGA_FIFO)
    );

    assign address_data_bus_c_to_m = data_out_CPU_to_FPGA_FIFO[31:0];
    assign address_on_c_to_m = data_out_CPU_to_FPGA_FIFO[32];
    assign data_on_c_to_m = data_out_CPU_to_FPGA_FIFO[33];
    assign read_en_c_to_m = data_out_CPU_to_FPGA_FIFO[34];
    assign write_en_c_to_m = data_out_CPU_to_FPGA_FIFO[35];

    // Asynchronous FIFO from CPU to FPGA

    // FPGA Signals
    // logic [35:0] data_in_FPGA_to_CPU_FIFO; // Driven
    // logic        w_en_FPGA_to_CPU_FIFO; // Driven
    // logic        full_FPGA_to_CPU_FIFO; // Uses

    // assign data_in_FPGA_to_CPU_FIFO = '0;

    // CPU Signals
    logic [35:0] data_out_FPGA_to_CPU_FIFO; // Uses
    logic        r_en_FPGA_to_CPU_FIFO; // Driven
    logic        empty_FPGA_to_CPU_FIFO; // Uses
    
    async_fifo FPGA_to_CPU_FIFO(
        .data_in(data_in_FPGA_to_CPU_FIFO),
        .w_en(w_en_FPGA_to_CPU_FIFO),
        .w_clk(fpga_clk), // 100 MHz
        .w_rst(rst), // Global Reset
        .full(full_FPGA_to_CPU_FIFO),

        .data_out(data_out_FPGA_to_CPU_FIFO),
        .r_en(r_en_FPGA_to_CPU_FIFO),
        .r_clk(clk), // 800 MHz
        .r_rst(rst), // Global Reset
        .empty(empty_FPGA_to_CPU_FIFO)
    );

    // Control Signals
    logic [3:0] read_counter; // 0 -> 7 + 1 overflow bit
    logic store_bmem_address;
    logic [31:0] latched_bmem_addr;
    logic rburst_counter;
    logic store_fpga_mem;

    always_ff @(posedge clk) begin
        if(rst) begin
            read_counter <= '0;
            latched_bmem_addr <= 'x;
            bmem_rdata <= 'x;
        end else begin
            if(r_en_FPGA_to_CPU_FIFO) read_counter <= read_counter + 4'd1;
            if(read_counter == 4'd8) read_counter <= '0;

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
        rburst_counter = 'x;
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
                                            1'b1, // Read Enable - ON
                                            1'b0, // Data On Bus - OFF
                                            1'b1, // Address On Bus - ON
                                            latched_bmem_addr};
                next_state = CPU_READ_DATA;
            end
            CPU_READ_DATA: begin // Wait for the FPGA to deliver the data over the FPGA_to_CPU_FIFO
                if(read_counter <= 4'd7) begin
                    next_state = CPU_READ_DATA;
                    if(!empty_FPGA_to_CPU_FIFO) begin
                        // Read the data that the FPGA writes back to the CPU
                        r_en_FPGA_to_CPU_FIFO = 1'b1;
                        case(read_counter)
                            4'd0: begin rburst_counter = 1'b0; bmem_rvalid = 1'b0; end
                            4'd1: begin rburst_counter = 1'b0; bmem_rvalid = 1'b0; store_fpga_mem = 1'b1; end
                            4'd2: begin rburst_counter = 1'b1; bmem_rvalid = 1'b0; store_fpga_mem = 1'b1; end
                            4'd3: begin rburst_counter = 1'b0; bmem_rvalid = 1'b1; store_fpga_mem = 1'b1; end
                            4'd4: begin rburst_counter = 1'b1; bmem_rvalid = 1'b0; store_fpga_mem = 1'b1; end
                            4'd5: begin rburst_counter = 1'b0; bmem_rvalid = 1'b1; store_fpga_mem = 1'b1; end
                            4'd6: begin rburst_counter = 1'b1; bmem_rvalid = 1'b0; store_fpga_mem = 1'b1; end
                            4'd7: begin rburst_counter = 1'b0; bmem_rvalid = 1'b1; store_fpga_mem = 1'b1; end
                        endcase
                    end
                end else begin
                    rburst_counter = 1'b1;
                    bmem_rvalid = 1'b0;
                    store_fpga_mem = 1'b1;
                    next_state = CPU_IDLE;
                end
            end
            CPU_SEND_WADDR: begin // Deliver the write address to the FPGA over the CPU_to_FPGA_FIFO

            end
            CPU_WRITE_DATA: begin // Deliver the write data to the FPGA over the CPU_to_FPGA_FIFO and wait for a response from FPGA that it wrote the data

            end
            default: begin
                w_en_CPU_to_FPGA_FIFO = 1'b0;
                r_en_FPGA_to_CPU_FIFO = 1'b0;
                bmem_ready = 1'b0;
                bmem_rvalid = 1'b0;
                store_fpga_mem = 1'b0;
                rburst_counter = 'x;
                next_state = state;
            end
        endcase
    end




    // logic resp_m_to_c_sync;
    // logic resp_m_to_c_sync_d;
    // logic resp_m_to_c_pulse;

    // always_ff @(posedge clk) begin : resp_synchronizer
    //     resp_m_to_c_sync <= resp_m_to_c; // Synchronize the initial signal
    // end

    // always_ff @(posedge clk) begin : resp_pulse_generator
    //     resp_m_to_c_sync_d <= resp_m_to_c_sync;
    // end
    // assign resp_m_to_c_pulse = ~resp_m_to_c_sync_d & resp_m_to_c_sync;

    // enum logic [4:0] {
    //     CPU_IDLE,
    //     // Read Operation
    //     CPU_SEND_READ_ADDR,
    //     CPU_SEND_READ_ADDR_WAIT,
    //     CPU_READ_DATA_1, 
    //     CPU_READ_DATA_2, 
    //     CPU_READ_DATA_3, 
    //     CPU_READ_DATA_4, 
    //     CPU_READ_DATA_5, 
    //     CPU_READ_DATA_6, 
    //     CPU_READ_DATA_7, 
    //     CPU_READ_DATA_8, 
    //     CPU_READ_DONE,
    //     // Write Operation
    //     CPU_SEND_WRITE_ADDR
    // } state, next_state;

    // logic [35:0] fifo_data_in;
    // logic [35:0] fifo_data_out;
    // logic        fifo_w_en;
    // logic        fifo_full;
    // // logic        fifo_empty;

    // async_fifo async_fifo(
    //     .data_in(fifo_data_in),
    //     .w_en(fifo_w_en),
    //     .w_clk(clk),
    //     .w_rst(rst),
    //     .full(fifo_full),

    //     .data_out(fifo_data_out),
    //     .r_en(r_en),
    //     .r_clk(fpga_clk),
    //     .r_rst(rst),
    //     .empty(fifo_empty) 
    // );

    // logic [31:0] rburst_counter;

    // logic [31:0] op_address; // Address to perform read or write
    // logic        fifo_in_address_on_c_to_m;
    // logic        fifo_in_data_on_c_to_m;
    // logic        fifo_in_read_en_c_to_m;
    // logic        fifo_in_write_en_c_to_m;

    // // Control Signals
    // logic store_bmem_address;
    // logic store_address_into_fifo;
    // logic store_data_from_fpga;
    // logic clear_relevant_data;


    // assign address_data_bus_c_to_m = fifo_data_out[31:0];
    // assign address_on_c_to_m = fifo_data_out[32];
    // assign data_on_c_to_m = fifo_data_out[33];
    // assign read_en_c_to_m = fifo_data_out[34];
    // assign write_en_c_to_m = fifo_data_out[35];


    // assign fifo_data_in[31:0] = store_address_into_fifo ? op_address : 'x;
    // assign fifo_data_in[32] = store_address_into_fifo ? fifo_in_address_on_c_to_m : 'x;
    // assign fifo_data_in[33] = store_address_into_fifo ? fifo_in_data_on_c_to_m : 'x;
    // assign fifo_data_in[34] = store_address_into_fifo ? fifo_in_read_en_c_to_m : 'x;
    // assign fifo_data_in[35] = store_address_into_fifo ? fifo_in_write_en_c_to_m : 'x;

    // always_ff @(posedge clk) begin
    //     if(rst || clear_relevant_data) begin
    //         op_address <= 'x;
    //         // fifo_data_in <= 'x;
    //         bmem_rdata <= 'x;
    //     end else begin
    //         if(store_bmem_address) begin
    //             op_address <= bmem_addr;
    //         end

    //         if(store_address_into_fifo) begin
    //             // fifo_data_in[31:0] <= op_address;
    //             // fifo_data_in[32] <= fifo_in_address_on_c_to_m;
    //             // fifo_data_in[33] <= fifo_in_data_on_c_to_m;
    //             // fifo_data_in[34] <= fifo_in_read_en_c_to_m;
    //             // fifo_data_in[35] <= fifo_in_write_en_c_to_m;
    //             bmem_raddr <= op_address;
    //         end

    //         if(store_data_from_fpga) begin
    //             bmem_rdata[32*rburst_counter +: 32] <= address_data_bus_m_to_c;
    //         end
    //     end
    // end

    // always_ff @(posedge clk) begin : update_state
    //     if(rst) begin
    //         state <= CPU_IDLE;
    //     end else begin
    //         state <= next_state;
    //     end
    // end

    // always_comb begin : next_state_logic
    //     bmem_ready = 1'b0;
    //     bmem_rvalid = 1'b0;
    //     fifo_w_en = 1'b0;
    //     store_bmem_address = 1'b0;
    //     store_address_into_fifo = 1'b0;
    //     store_data_from_fpga = 1'b0;
    //     clear_relevant_data = 1'b0;
    //     rburst_counter = 32'd0;
    //     fifo_in_address_on_c_to_m = 1'b0; 
    //     fifo_in_data_on_c_to_m = 1'b0; 
    //     fifo_in_read_en_c_to_m = 1'b0; 
    //     fifo_in_write_en_c_to_m = 1'b0; 
    //     next_state = state;
    //     unique case(state)
    //         CPU_IDLE: begin
    //             bmem_ready = 1'b1; // Allow for memory to be accessed
    //             if(bmem_read) begin
    //                 store_bmem_address = 1'b1; // Store the memory address
    //                 next_state = CPU_SEND_READ_ADDR; // Send the address to read from
    //             end else if(bmem_write) begin
    //                 store_bmem_address = 1'b1; // Store the memory address
    //                 next_state = CPU_SEND_WRITE_ADDR; // Send the address to write to
    //             end else begin
    //                 clear_relevant_data = 1'b1;
    //                 next_state = CPU_IDLE; 
    //             end
    //         end
    //         CPU_SEND_READ_ADDR: begin
    //             if(!fifo_full) begin
    //                 fifo_w_en = 1'b1; // Enable the writes to FIFO memory
    //                 store_address_into_fifo = 1'b1; // Update data going into FIFO to address
    //                 fifo_in_address_on_c_to_m = 1'b1; // Address is on the bus
    //                 fifo_in_data_on_c_to_m = 1'b0; // Data is not on the bus
    //                 fifo_in_read_en_c_to_m = 1'b1; // Performing a read operation
    //                 fifo_in_write_en_c_to_m = 1'b0; // Performing a write operation
    //                 next_state = CPU_SEND_READ_ADDR_WAIT;
    //                 // if(resp_m_to_c) begin
    //                 //     next_state = READ_DATA_1; // Wait for a response so that we can read the FPGA data
    //                 // end else begin
    //                 //     next_state = SEND_READ_ADDR;
    //                 // end
    //             end else begin
    //                 next_state = CPU_SEND_READ_ADDR;
    //             end
    //         end
    //         CPU_READ_FPGA_DATA: begin 


    //         end
    //         CPU_SEND_READ_ADDR_WAIT: begin // Wait for the FPGA to ack the address
    //             if(resp_m_to_c_pulse) begin
    //                 next_state = CPU_READ_DATA_1;
    //             end else begin
    //                 next_state = CPU_SEND_READ_ADDR_WAIT;
    //             end
    //         end            
    //         CPU_READ_DATA_1: begin
    //             // After the FPGA responds to the address, it will take another 8 cycles to start reading the data
    //             if(resp_m_to_c_pulse) begin
    //                 store_data_from_fpga = 1'b1; // Once we get a response from the fpga, we can store its data
    //                 fifo_in_address_on_c_to_m = 1'b0; // Address is not on the bus
    //                 fifo_in_data_on_c_to_m = 1'b1; // Data is on the bus
    //                 fifo_in_read_en_c_to_m = 1'b1; // Performing a read operation
    //                 fifo_in_write_en_c_to_m = 1'b0; // Performing a write operation
    //                 next_state = CPU_READ_DATA_2;
    //             end else begin
    //                 next_state = CPU_READ_DATA_1;
    //             end
    //         end
    //         CPU_READ_DATA_2: begin
    //             if(resp_m_to_c_pulse) begin
    //                 rburst_counter = 32'd1;
    //                 store_data_from_fpga = 1'b1; // Once we get a response from the fpga, we can store its data
    //                 fifo_in_address_on_c_to_m = 1'b0; // Address is not on the bus
    //                 fifo_in_data_on_c_to_m = 1'b1; // Data is on the bus
    //                 fifo_in_read_en_c_to_m = 1'b1; // Performing a read operation
    //                 fifo_in_write_en_c_to_m = 1'b0; // Performing a write operation
    //                 bmem_rvalid = 1'b1;
    //                 next_state = CPU_READ_DATA_3;
    //             end else begin
    //                 next_state = CPU_READ_DATA_2;
    //             end
    //         end
    //         CPU_READ_DATA_3: begin
    //             if(resp_m_to_c_pulse) begin
    //                 store_data_from_fpga = 1'b1; // Once we get a response from the fpga, we can store its data
    //                 fifo_in_address_on_c_to_m = 1'b0; // Address is not on the bus
    //                 fifo_in_data_on_c_to_m = 1'b1; // Data is on the bus
    //                 fifo_in_read_en_c_to_m = 1'b1; // Performing a read operation
    //                 fifo_in_write_en_c_to_m = 1'b0; // Performing a write operation
    //                 next_state = CPU_READ_DATA_4;
    //             end else begin
    //                 next_state = CPU_READ_DATA_3;
    //             end
    //         end
    //         CPU_READ_DATA_4: begin
    //             if(resp_m_to_c_pulse) begin
    //                 rburst_counter = 32'd1;
    //                 store_data_from_fpga = 1'b1; // Once we get a response from the fpga, we can store its data
    //                 fifo_in_address_on_c_to_m = 1'b0; // Address is not on the bus
    //                 fifo_in_data_on_c_to_m = 1'b1; // Data is on the bus
    //                 fifo_in_read_en_c_to_m = 1'b1; // Performing a read operation
    //                 fifo_in_write_en_c_to_m = 1'b0; // Performing a write operation
    //                 bmem_rvalid = 1'b1;
    //                 next_state = CPU_READ_DATA_5;
    //             end else begin
    //                 next_state = CPU_READ_DATA_4;
    //             end
    //         end
    //         CPU_READ_DATA_5: begin
    //             if(resp_m_to_c_pulse) begin
    //                 store_data_from_fpga = 1'b1; // Once we get a response from the fpga, we can store its data
    //                 fifo_in_address_on_c_to_m = 1'b0; // Address is not on the bus
    //                 fifo_in_data_on_c_to_m = 1'b1; // Data is on the bus
    //                 fifo_in_read_en_c_to_m = 1'b1; // Performing a read operation
    //                 fifo_in_write_en_c_to_m = 1'b0; // Performing a write operation
    //                 next_state = CPU_READ_DATA_6;
    //             end else begin
    //                 next_state = CPU_READ_DATA_5;
    //             end
    //         end
    //         CPU_READ_DATA_6: begin
    //             if(resp_m_to_c_pulse) begin
    //                 rburst_counter = 32'd1;
    //                 store_data_from_fpga = 1'b1; // Once we get a response from the fpga, we can store its data
    //                 fifo_in_address_on_c_to_m = 1'b0; // Address is not on the bus
    //                 fifo_in_data_on_c_to_m = 1'b1; // Data is on the bus
    //                 fifo_in_read_en_c_to_m = 1'b1; // Performing a read operation
    //                 fifo_in_write_en_c_to_m = 1'b0; // Performing a write operation
    //                 bmem_rvalid = 1'b1;
    //                 next_state = CPU_READ_DATA_7;
    //             end else begin
    //                 next_state = CPU_READ_DATA_6;
    //             end
    //         end
    //         CPU_READ_DATA_7: begin
    //             if(resp_m_to_c_pulse) begin
    //                 store_data_from_fpga = 1'b1; // Once we get a response from the fpga, we can store its data
    //                 fifo_in_address_on_c_to_m = 1'b0; // Address is not on the bus
    //                 fifo_in_data_on_c_to_m = 1'b1; // Data is on the bus
    //                 fifo_in_read_en_c_to_m = 1'b1; // Performing a read operation
    //                 fifo_in_write_en_c_to_m = 1'b0; // Performing a write operation
    //                 next_state = CPU_READ_DATA_8;
    //             end else begin
    //                 next_state = CPU_READ_DATA_7;
    //             end
    //         end
    //         CPU_READ_DATA_8: begin
    //             if(resp_m_to_c_pulse) begin
    //                 rburst_counter = 32'd1;
    //                 store_data_from_fpga = 1'b1; // Once we get a response from the fpga, we can store its data
    //                 fifo_in_address_on_c_to_m = 1'b0; // Address is not on the bus
    //                 fifo_in_data_on_c_to_m = 1'b1; // Data is on the bus
    //                 fifo_in_read_en_c_to_m = 1'b1; // Performing a read operation
    //                 fifo_in_write_en_c_to_m = 1'b0; // Performing a write operation
    //                 bmem_rvalid = 1'b1;
    //                 next_state = CPU_READ_DONE;
    //             end else begin
    //                 next_state = CPU_READ_DATA_8;
    //             end
    //         end
    //         CPU_READ_DONE: begin
    //             next_state = CPU_IDLE;
    //         end
    //         default: begin
    //             bmem_ready = 1'b0;
    //             bmem_rvalid = 1'b0;
    //             fifo_w_en = 1'b0;
    //             store_bmem_address = 1'b0;
    //             store_address_into_fifo = 1'b0;
    //             store_data_from_fpga = 1'b0;
    //             clear_relevant_data = 1'b0;
    //             rburst_counter = 32'd0;
    //             fifo_in_address_on_c_to_m = 1'b0; 
    //             fifo_in_data_on_c_to_m = 1'b0; 
    //             fifo_in_read_en_c_to_m = 1'b0; 
    //             fifo_in_write_en_c_to_m = 1'b0; 
    //             next_state = state;
    //         end
    //     endcase
    // end

    // enum logic [4:0]{
    //     IDLE,
    //     READ_ADDR,
    //     READ_DATA_1,
    //     READ_DATA_2,
    //     READ_DATA_3,
    //     READ_DATA_4,
    //     READ_DATA_5,
    //     READ_DATA_6,
    //     READ_DATA_7,
    //     READ_DATA_8,
    //     READ_DONE,
    //     WRITE_ADDR,
    //     WRITE_DATA_1,
    //     WRITE_DATA_2,
    //     WRITE_DATA_3,
    //     WRITE_DATA_4,
    //     WRITE_DATA_5,
    //     WRITE_DATA_6,
    //     WRITE_DATA_7,
    //     WRITE_DATA_8,
    //     WAIT_UNTIL_BMEM_WRITE_OFF,
    //     WRITE_DONE
    // } state, state_next;

    // logic write_addr, write_data;
    // logic read_addr, read_data;
    // logic [31:0] rburst_counter;
    // logic latch_bmem_rdata, unlatch_bmem_rdata;
    
    // always_ff @(posedge clk) begin
    //     if(rst) begin
    //         address_data_bus_c_to_m <= 'x;
    //         address_on_c_to_m <= 1'b0;
    //         data_on_c_to_m <= 1'b0;
    //         read_en_c_to_m <= 1'b0;
    //         write_en_c_to_m <= 1'b0;
    //         state <= IDLE;
    //     end else begin
    //         if(latch_bmem_rdata) begin
    //             address_data_bus_c_to_m <= bmem_addr;
    //         end else if(unlatch_bmem_rdata) begin
    //             address_data_bus_c_to_m <= 'x;
    //             bmem_raddr <= 'x;
    //             bmem_rdata <= 'x;
    //         end else if(write_addr) begin
    //             // address_data_bus_c_to_m <= bmem_addr;
    //             address_on_c_to_m <= 1'b1;
    //             data_on_c_to_m <= 1'b1;
    //             read_en_c_to_m <= 1'b0;
    //             write_en_c_to_m <= 1'b1;
    //         end else if(write_data) begin
    //             address_data_bus_c_to_m <= bmem_wdata[32*wburst_counter +: 32];
    //             data_on_c_to_m <= 1'b1;
    //             address_on_c_to_m <= 1'b0;
    //             read_en_c_to_m <= 1'b0;
    //             write_en_c_to_m <= 1'b1;
    //         end else if(read_addr) begin
    //             // address_data_bus_c_to_m <= bmem_addr;
    //             bmem_raddr <= address_data_bus_c_to_m;
    //             address_on_c_to_m <= 1'b1;
    //             data_on_c_to_m <= 1'b0;
    //             read_en_c_to_m <= 1'b1;
    //             write_en_c_to_m <= 1'b0;
    //         end else if(read_data) begin
    //             if(resp_m_to_c) begin
    //                 bmem_rdata[32*rburst_counter +: 32] <= address_data_bus_m_to_c;
    //             end
    //             address_on_c_to_m <= 1'b0;
    //             data_on_c_to_m <= 1'b1;
    //             read_en_c_to_m <= 1'b1;
    //             write_en_c_to_m <= 1'b0;
    //         end else begin
    //             bmem_rdata <= 'x;
    //             address_data_bus_c_to_m <= 'x;
    //             address_on_c_to_m <= 1'b0;
    //             data_on_c_to_m <= 1'b0;
    //             read_en_c_to_m <= 1'b0;
    //             write_en_c_to_m <= 1'b0;
    //         end

    //     state <= state_next;
    //     end
    // end

    // always_comb begin
    //     state_next = state;
    //     wburst_counter = 1'b0;
    //     write_addr = 1'b0;
    //     write_data = 1'b0;
    //     rburst_counter = 32'd0;
    //     read_addr = 1'b0;
    //     read_data = 1'b0;
    //     bmem_ready = 1'b0;
    //     bmem_rvalid = 1'b0;
    //     latch_bmem_rdata = 1'b0;
    //     unlatch_bmem_rdata = 1'b0;
    //     case(state)
    //     IDLE: begin
    //         bmem_ready = 1'b1;
    //         if(bmem_read) begin
    //             state_next = READ_ADDR;
    //             // Latch BMEM_ADDR
    //             latch_bmem_rdata = 1'b1;
    //         end else if(bmem_write) begin
    //             state_next = WRITE_ADDR;
    //             latch_bmem_rdata = 1'b1;
    //         end else begin  
    //             state_next = state_next;
    //         end
    //     end
    //     WRITE_ADDR: begin
    //         write_addr = 1'b1;
    //         if(resp_m_to_c) begin
    //             state_next = WRITE_DATA_1;
    //         end else begin
    //             state_next = state_next;
    //         end
    //     end
    //     WRITE_DATA_1: begin
    //         write_data = 1'b1;
    //         if(resp_m_to_c) begin
    //             state_next = WRITE_DATA_2;
    //         end else begin
    //             state_next = state_next;
    //         end
    //     end
    //     WRITE_DATA_2: begin
    //         write_data = 1'b1;
    //         wburst_counter = 1'b1;
    //         if(resp_m_to_c) begin
    //             state_next = WRITE_DATA_3;
    //         end else begin
    //             state_next = state_next;
    //         end
    //     end
    //     WRITE_DATA_3: begin
    //         write_data = 1'b1;
    //         if(resp_m_to_c) begin
    //             state_next = WRITE_DATA_4;
    //         end else begin
    //             state_next = state_next;
    //         end
    //     end
    //     WRITE_DATA_4: begin
    //         write_data = 1'b1;
    //         wburst_counter = 1'b1;
    //         if(resp_m_to_c) begin
    //             state_next = WRITE_DATA_5;
    //         end else begin
    //             state_next = state_next;
    //         end
    //     end
    //     WRITE_DATA_5: begin
    //         write_data = 1'b1;
    //         if(resp_m_to_c) begin
    //             state_next = WRITE_DATA_6;
    //         end else begin
    //             state_next = state_next;
    //         end
    //     end
    //     WRITE_DATA_6: begin
    //         write_data = 1'b1;
    //         wburst_counter = 1'b1;
    //         if(resp_m_to_c) begin
    //             state_next = WRITE_DATA_7;
    //         end else begin
    //             state_next = state_next;
    //         end
    //     end
    //     WRITE_DATA_7: begin
    //         write_data = 1'b1;
    //         if(resp_m_to_c) begin
    //             state_next = WRITE_DATA_8;
    //         end else begin
    //             state_next = state_next;
    //         end
    //     end
    //     WRITE_DATA_8: begin
    //         write_data = 1'b1;
    //         wburst_counter = 1'b1;
    //         if(resp_m_to_c) begin
    //             state_next = WRITE_DONE;
    //         end else begin
    //             state_next = state_next;
    //         end
    //     end
    //     WRITE_DONE: begin
    //         write_data = 1'b1;
    //         if(resp_m_to_c) begin//write_resp_chan signaling write transaction is finished 
    //             // wait until bmem_write is off
    //             bmem_ready = 1'b1;
                
    //             state_next = WAIT_UNTIL_BMEM_WRITE_OFF;
    //         end else begin
    //             state_next = state_next; 
    //         end
    //     end
    //     WAIT_UNTIL_BMEM_WRITE_OFF: begin
    //         if(bmem_write) begin
    //             state_next = state_next;
    //         end else begin
    //             unlatch_bmem_rdata = 1'b1;
    //             write_data = 1'b0;
    //             state_next = IDLE;
    //         end
    //     end

    //     READ_ADDR: begin
    //         read_addr = 1'b1;
    //         if(resp_m_to_c) begin
    //             state_next = READ_DATA_1;
    //         end else begin
    //             state_next = state_next; 
    //         end
    //     end
    //     READ_DATA_1: begin
    //         read_data = 1'b1;
    //         if(resp_m_to_c) begin
    //             // bmem_rvalid = 1'b1;
    //             state_next = READ_DATA_2;
    //         end else begin
    //             state_next = state_next;
    //         end
    //     end
    //     READ_DATA_2: begin
    //         read_data = 1'b1;
    //         rburst_counter = 32'd1;
    //         if(resp_m_to_c) begin
    //             // bmem_rvalid = 1'b1;
    //             state_next = READ_DATA_3;
    //         end else begin
    //             state_next = state_next;
    //         end
    //     end
    //     READ_DATA_3: begin
    //         read_data = 1'b1;
    //         rburst_counter = 32'd0;
    //         if(resp_m_to_c) begin
    //             bmem_rvalid = 1'b1;
    //             state_next = READ_DATA_4;
    //         end else begin
    //             state_next = state_next;
    //         end
    //     end
    //     READ_DATA_4: begin
    //         read_data = 1'b1;
    //         rburst_counter = 32'd1;
    //         if(resp_m_to_c) begin
    //             // bmem_rvalid = 1'b1;
    //             state_next = READ_DATA_5;
    //         end else begin
    //             state_next = state_next;
    //         end
    //     end
    //     READ_DATA_5: begin
    //         read_data = 1'b1;
    //         rburst_counter = 32'd0;
    //         if(resp_m_to_c) begin
    //             bmem_rvalid = 1'b1;
    //             state_next = READ_DATA_6;
    //         end else begin
    //             state_next = state_next;
    //         end
    //     end
    //     READ_DATA_6: begin
    //         read_data = 1'b1;
    //         rburst_counter = 32'd1;
    //         if(resp_m_to_c) begin
    //             // bmem_rvalid = 1'b1;
    //             state_next = READ_DATA_7;
    //         end else begin
    //             state_next = state_next;
    //         end
    //     end

    //     READ_DATA_7: begin
    //         read_data = 1'b1;
    //         rburst_counter = 32'd0;
    //         if(resp_m_to_c) begin
    //             bmem_rvalid = 1'b1;
    //             state_next = READ_DATA_8;
    //         end else begin
    //             state_next = state_next;
    //         end
    //     end
    //     READ_DATA_8: begin
    //         read_data = 1'b1;
    //         rburst_counter = 32'd1;
    //         if(resp_m_to_c) begin
    //             // bmem_rvalid = 1'b1;
    //             state_next = READ_DONE;
    //         end else begin
    //             state_next = state_next;
    //         end
    //     end

    //     READ_DONE: begin
    //         bmem_rvalid = 1'b1;
    //         read_data = 1'b0;
    //         unlatch_bmem_rdata = 1'b1;
    //         state_next = IDLE;
    //     end
    //     endcase

    // end    
    



endmodule