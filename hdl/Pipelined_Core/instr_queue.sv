/* README:
    Parameterizeable circular queue with variable width and depth.
    Parameters: WIDTH = size of each queue entry in bits
                DEPTH = number of queue entries
    Will be used for: 
    Instruction Queue 
*/
module instr_queue 
import rv32i_types::*;
(   
    input   logic   clk, rst, 
    input   logic   push, pop,
    input   logic   flush,
    input   iq_entry_t  rdata,
    output  iq_entry_t wdata,
    output  logic    full, empty,
    output  logic [$clog2(IQ_DEPTH):0] IQ_num_contents
);
    iq_entry_t queue_body [IQ_DEPTH];  
    iq_entry_t queue_body_next [IQ_DEPTH];
    logic [$clog2(IQ_DEPTH):0] head_ptr, tail_ptr, head_ptr_next, tail_ptr_next;
    logic [$clog2(IQ_DEPTH):0] num_contents, num_contents_next;
    assign IQ_num_contents = num_contents;
    always_ff @ (posedge clk) begin
        if(rst) begin
            head_ptr <= '0;
            tail_ptr <= '0;
            num_contents <= '0;
            queue_body <= '{default:'0};
        end
        else begin
            queue_body <= queue_body_next;
            head_ptr <= head_ptr_next;
            tail_ptr <= tail_ptr_next;
            num_contents <= num_contents_next;
        end
    end

    /* function for updating and maintaining tail_ptr */
    always_comb begin
        queue_body_next = queue_body;
        num_contents_next = num_contents;
        tail_ptr_next = tail_ptr;
        head_ptr_next = head_ptr;
        wdata = '{default:'x};
        if(flush) begin
            tail_ptr_next = '0;
            head_ptr_next = '0;
            num_contents_next = '0;
        end else begin
            // for(int i = 0; i < 1; i++) begin
                if(push) begin
                    queue_body_next[tail_ptr_next[$clog2(IQ_DEPTH)-1:0]] = rdata;
                    num_contents_next  = num_contents_next + 1'd1;
                    tail_ptr_next = tail_ptr_next + 'd1 < IQ_DEPTH ? tail_ptr_next + 1'd1 : '0;
                end
            // end
            // for(int i = 0; i < 1; i++) begin
                if(pop) begin
                    wdata = queue_body[head_ptr_next[$clog2(IQ_DEPTH)-1:0]];
                    head_ptr_next = head_ptr_next + 'd1 < IQ_DEPTH ? head_ptr_next + 1'd1 : '0;
                    num_contents_next = num_contents_next - 1'd1;
                end
            // end
        end
    end
    
    /* function for checking if queue is full or empty */
    assign full = unsigned'(num_contents) > unsigned'(5'(IQ_DEPTH - 1));
  
    assign empty = num_contents == '0;

endmodule : instr_queue