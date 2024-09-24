module amo_unit (

    input logic clk,                 // Clock signal
    input logic rst,                 // Reset signal
    input logic amo_valid,           // Signal that an AMO instruction is in the MEM stage
    input logic [31:0] mem_data_in,  // Data read from memory
    input logic [31:0] amo_operand,  // Operand for AMO operation
    input logic [2:0] amo_funct,     // AMO function code (e.g., ADD, AND, OR, XOR)

    input logic       mem_resp,

    output logic [31:0] mem_data_out,// Data to write to memory
    output logic amo_done,           // Flag indicating AMO completion
    output logic mem_read,           // Control signal for memory read
    output logic mem_write,           // Control signal for memory write


    // locking stuff
    output  logic   [31:0]     locked_address,
    output  logic              lock,

    input   logic   [31:0]     address_to_lock
);

    // Define states in lowercase
    enum logic [2:0] {
        idle ,
        load ,
        calc ,
        store,
        done,
        lwr,
        swc 
    } state, next_state;

    logic [31:0] loaded_value, computed_value;

    // State transition logic
    always_ff @(posedge clk) begin

        if (rst) begin

            state <= idle;
            loaded_value <= 32'b0;
            computed_value <= 32'b0;

        end else begin
            
            state <= next_state;

            // Retain loaded_value and computed_value across states
            case (next_state)
                load: begin
                    // Capture the memory value during load state
                    loaded_value <= mem_data_in;
                end
                calc: begin
                    // Perform the calculation during calc state
                    case (amo_funct)
                        3'b000: computed_value <= loaded_value + amo_operand;  // AMO ADD
                        3'b001: computed_value <= loaded_value & amo_operand;  // AMO AND
                        3'b010: computed_value <= loaded_value | amo_operand;  // AMO OR
                        3'b011: computed_value <= loaded_value ^ amo_operand;  // AMO XOR
                
                        default: computed_value <= loaded_value;
                    endcase
                end
            endcase
        end
    end



    always_comb begin

        mem_read = 1'b0;
        mem_write = 1'b0;
        amo_done = 1'b0;
        mem_data_out = 32'b0;
        next_state = state;

        locked_address = '0;
        lock = 1'b0;

        case (state)
            idle: begin
                if (amo_valid) begin
                    mem_read = 1'b1;
                    next_state = load;
                end
            end

            load: begin
                mem_read = 1'b1;
                lock = 1'b1;
                locked_address = address_to_lock;
                if (mem_resp) next_state = calc;
            end

            lwr : begin
                mem_read = 1'b1;
                lock = 1'b1;
                locked_address = address_to_lock;
                if(mem_resp) next_state = done;
            end

            calc: begin
                next_state = store;
            end

            store: begin
                mem_write = 1'b1;
                mem_data_out = computed_value;
                if (mem_resp) next_state = done;
            end

            swc : begin
                mem_write = 1'b1;
                mem_data_out = computed_value;
                if (mem_resp) next_state = done;
            end

            done: begin
                amo_done = 1'b1;
                next_state = idle;
            end

            default: next_state = idle;
        endcase
    end

endmodule
