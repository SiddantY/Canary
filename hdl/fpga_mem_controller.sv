module fpga_mem_controller(
    input   logic clk,
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

    // Memory -> Controller
    input logic [31:0] address_data_bus_m_to_c,
    input logic resp_m_to_c,

    // Controller -> Memory
    output logic [31:0] address_data_bus_c_to_m,
    output logic address_on_c_to_m,
    output logic data_on_c_to_m,
    output logic read_en_c_to_m,
    output logic write_en_c_to_m
);

    enum logic [4:0]{
        IDLE,
        READ_ADDR,
        READ_DATA_1,
        READ_DATA_2,
        READ_DATA_3,
        READ_DATA_4,
        READ_DATA_5,
        READ_DATA_6,
        READ_DATA_7,
        READ_DATA_8,
        READ_DONE,
        WRITE_ADDR,
        WRITE_DATA_1,
        WRITE_DATA_2,
        WRITE_DONE
    } state, state_next;

    logic wburst_counter, write_addr, write_data;
    logic read_addr, read_data;
    logic [31:0] rburst_counter;
    logic latch_bmem_rdata, unlatch_bmem_rdata;
    
    always_ff @(posedge clk) begin
        if(rst) begin
            address_data_bus_c_to_m <= 'x;
            address_on_c_to_m <= 1'b0;
            data_on_c_to_m <= 1'b0;
            read_en_c_to_m <= 1'b0;
            write_en_c_to_m <= 1'b0;
            state <= IDLE;
        end else begin
            if(latch_bmem_rdata) begin
                address_data_bus_c_to_m <= bmem_addr;
            end else if(unlatch_bmem_rdata) begin
                address_data_bus_c_to_m <= 'x;
                bmem_rdata <= 'x;
            end else if(write_addr) begin
                // address_data_bus_c_to_m <= bmem_addr;
                address_on_c_to_m <= 1'b1;
                data_on_c_to_m <= 1'b0;
                read_en_c_to_m <= 1'b0;
                write_en_c_to_m <= 1'b1;
            end else if(write_data) begin
                address_data_bus_c_to_m <= bmem_wdata[32*wburst_counter +: 32];//not 1000% guranteed
                data_on_c_to_m <= 1'b1;
                address_on_c_to_m <= 1'b0;
                read_en_c_to_m <= 1'b0;
                write_en_c_to_m <= 1'b1;
            end else if(read_addr) begin
                // address_data_bus_c_to_m <= bmem_addr;
                bmem_raddr <= address_data_bus_c_to_m;
                address_on_c_to_m <= 1'b1;
                data_on_c_to_m <= 1'b0;
                read_en_c_to_m <= 1'b1;
                write_en_c_to_m <= 1'b0;
            end else if(read_data) begin
                if(resp_m_to_c) begin
                    bmem_rdata[32*rburst_counter +: 32] <= address_data_bus_m_to_c;
                end
                address_on_c_to_m <= 1'b0;
                data_on_c_to_m <= 1'b1;
                read_en_c_to_m <= 1'b1;
                write_en_c_to_m <= 1'b0;
            end else begin
                bmem_rdata <= 'x;
                address_data_bus_c_to_m <= 'x;
                address_on_c_to_m <= 1'b0;
                data_on_c_to_m <= 1'b0;
                read_en_c_to_m <= 1'b0;
                write_en_c_to_m <= 1'b0;
            end

        state <= state_next;
        end
    end

    always_comb begin
        state_next = state;
        wburst_counter = 1'b0;
        write_addr = 1'b0;
        write_data = 1'b0;
        rburst_counter = 32'd0;
        read_addr = 1'b0;
        read_data = 1'b0;
        bmem_ready = 1'b0;
        bmem_rvalid = 1'b0;
        latch_bmem_rdata = 1'b0;
        unlatch_bmem_rdata = 1'b0;
        case(state)
        IDLE: begin
            bmem_ready = 1'b1;
            if(bmem_read) begin
                state_next = READ_ADDR;
                // Latch BMEM_ADDR
                latch_bmem_rdata = 1'b1;
            end else if(bmem_write) begin
                state_next = WRITE_ADDR;
            end else begin  
                state_next = state_next;
            end
        end
        WRITE_ADDR: begin
            write_addr = 1'b1;
            if(resp_m_to_c) begin
                state_next = WRITE_DATA_1;
            end else begin
                state_next = state_next;
            end
        end
        WRITE_DATA_1: begin
            write_data = 1'b1;
            if(resp_m_to_c) begin
                state_next = WRITE_DATA_2;
            end else begin
                state_next = state_next;
            end
        end
        WRITE_DATA_2: begin
            write_data = 1'b1;
            wburst_counter = 1'b1;
            if(resp_m_to_c) begin
                state_next = WRITE_DONE;
            end else begin
                state_next = state_next;
            end
        end
        WRITE_DONE: begin
            if(resp_m_to_c) begin//write_resp_chan signaling write transaction is finished 
                write_data = 1'b0;
                state_next = IDLE;
            end else begin
                state_next = state_next; 
            end
        end
        READ_ADDR: begin
            read_addr = 1'b1;
            if(resp_m_to_c) begin
                state_next = READ_DATA_1;
            end else begin
                state_next = state_next; 
            end
        end
        READ_DATA_1: begin
            read_data = 1'b1;
            if(resp_m_to_c) begin
                // bmem_rvalid = 1'b1;
                state_next = READ_DATA_2;
            end else begin
                state_next = state_next;
            end
        end
        READ_DATA_2: begin
            read_data = 1'b1;
            rburst_counter = 32'd1;
            if(resp_m_to_c) begin
                // bmem_rvalid = 1'b1;
                state_next = READ_DATA_3;
            end else begin
                state_next = state_next;
            end
        end
        READ_DATA_3: begin
            read_data = 1'b1;
            rburst_counter = 32'd0;
            if(resp_m_to_c) begin
                bmem_rvalid = 1'b1;
                state_next = READ_DATA_4;
            end else begin
                state_next = state_next;
            end
        end
        READ_DATA_4: begin
            read_data = 1'b1;
            rburst_counter = 32'd1;
            if(resp_m_to_c) begin
                // bmem_rvalid = 1'b1;
                state_next = READ_DATA_5;
            end else begin
                state_next = state_next;
            end
        end
        READ_DATA_5: begin
            read_data = 1'b1;
            rburst_counter = 32'd0;
            if(resp_m_to_c) begin
                bmem_rvalid = 1'b1;
                state_next = READ_DATA_6;
            end else begin
                state_next = state_next;
            end
        end
        READ_DATA_6: begin
            read_data = 1'b1;
            rburst_counter = 32'd1;
            if(resp_m_to_c) begin
                // bmem_rvalid = 1'b1;
                state_next = READ_DATA_7;
            end else begin
                state_next = state_next;
            end
        end

        READ_DATA_7: begin
            read_data = 1'b1;
            rburst_counter = 32'd0;
            if(resp_m_to_c) begin
                bmem_rvalid = 1'b1;
                state_next = READ_DATA_8;
            end else begin
                state_next = state_next;
            end
        end
        READ_DATA_8: begin
            read_data = 1'b1;
            rburst_counter = 32'd1;
            if(resp_m_to_c) begin
                // bmem_rvalid = 1'b1;
                state_next = READ_DONE;
            end else begin
                state_next = state_next;
            end
        end

        READ_DONE: begin
            bmem_rvalid = 1'b1;
            read_data = 1'b0;
            unlatch_bmem_rdata = 1'b1;
            state_next = IDLE;
        end
        endcase

    end    
    



endmodule