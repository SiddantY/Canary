module snoop_cache (
    input   logic           clk,
    input   logic           rst,

    // cpu side signals, ufp -> upward facing port
    input   logic   [31:0]  ufp_addr,
    input   logic   [3:0]   ufp_rmask,
    input   logic   [3:0]   ufp_wmask,
    output  logic   [31:0]  ufp_rdata,
    input   logic   [31:0]  ufp_wdata,
    output  logic           ufp_resp,

    // memory side signals, dfp -> downward facing port
    output  logic   [31:0]  dfp_addr,
    output  logic           dfp_read,
    output  logic           dfp_write,
    input   logic   [255:0] dfp_rdata,
    output  logic   [255:0] dfp_wdata,
    input   logic           dfp_resp,


    // Bus Signals
    input   logic           bus_ready
);

// Define the state encoding using typedef enum
    enum logic [2:0] {
        IDLE       ,
        COMP_TAG   ,
        WAIT       ,
        READ_BUS   ,
        ACQUIRE_BUS,
        WB         
    } current_state, next_state;


    // State transition logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) 
            current_state <= IDLE;
        else 
            current_state <= next_state;
    end

    // Next state logic based on current state and inputs
    always_comb begin
        // Default values
        next_state = current_state;
        write_enable = 0;
        acquire_bus = 0;
        read_bus = 0;

        case (current_state)
            IDLE: begin
                if (ufp_rmask != '0 || ufp_wmask != '0) next_state = COMP_TAG;
                else next_state = IDLE;
            end

            COMP_TAG: begin
                if (cache_hit) next_state = IDLE;
                else if 
                    next_state = ACQUIRE_BUS;
                end 
            end

            WAIT: begin
                if (bus_ready) begin
                    next_state = READ_BUS;
                end
            end

            READ_BUS: begin
                if (bus_resp) begin
                    next_state = WB;
                    read_bus = 1'b1;
                end
            end

            ACQUIRE_BUS: begin
                acquire_bus = 1'b1;
                next_state = WB;
            end

            WB: begin
                write_enable = 1;
                if (mem_response) begin
                    next_state = IDLE;
                end
            end

            default: next_state = IDLE;
        endcase
    end


