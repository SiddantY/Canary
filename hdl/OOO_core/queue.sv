/*
Paremeterized Queue:
    rst -> assertion of reset should clear queue
    data_in -> data to add to the end of the queue
    write_enable -> if write_enable is asserted we can add elements to the queue.
    read_enable -> if read enable is asserted we can now read from the queue, first elements is popped off
    data_out -> data from the front of the queue.
*/
// `default_nettype none
module queue 
#(
    parameter   DATA_WIDTH  =   64, 
    parameter   QUEUE_DEPTH =   64,
    parameter RD_PTR_INCR = 1
)

(
    input   logic                       clk,
    input   logic                       rst,
    input   logic   [DATA_WIDTH-1:0]    data_in,
    input   logic                       write_enable,
    input   logic                       read_enable,
    input   logic                       jump_en,
    input   logic                       jalr_en, jalr_done,
    input   logic                       flush,
    output  logic                       queue_empty,
    output  logic                       queue_full, 
    output  logic                       queue_full_param, 
    output  logic   [DATA_WIDTH-1:0]    data_out,
    output  logic                       read_resp
);

logic [DATA_WIDTH-1:0] data_queue [QUEUE_DEPTH]; // queue

logic [$clog2(QUEUE_DEPTH)-1:0] read_ptr; // read loc
logic [$clog2(QUEUE_DEPTH)-1:0] write_ptr; // write loc

logic jalr_en_latch;

int i;
always_ff @(posedge clk)
    begin
        if(rst || flush) // clear the queue
            begin
                for(i = 0; i < QUEUE_DEPTH; i = i+1) // set queue to zeroes
                    begin
                        data_queue[i%QUEUE_DEPTH] <= '0;
                    end

                //set pointers to 0
                read_ptr <= '0;
                write_ptr <= '0;

                read_resp <= '0;

                jalr_en_latch <= '0;
            end
        else 
            begin
                if(read_enable && ~queue_empty) // read asserted send out first element and pop it off the queue
                    begin
                        data_out <= data_queue[read_ptr];
                        read_ptr <= read_ptr + 1'b1;
                        read_resp <= 1'b1;
                    end
                else
                    begin
                        data_out <= 'x;
                        read_resp <= 1'b0;
                    end

                if(write_enable && ~queue_full) // write asserted take the data_in and put it at the back of the queue
                    begin
                        data_queue[write_ptr] <= data_in;
                        write_ptr <= write_ptr + 1'b1;
                    end
                
                if(jump_en)
                    begin
                        read_ptr <= read_ptr + 2'b10;
                        write_ptr <= read_ptr + 2'b10;
                        read_resp <= 1'b0;
                    end
                
                if(jalr_en)
                    begin
                        jalr_en_latch <= 1'b1;
                        read_resp <= '0;
                    end
                
                if(jalr_en_latch)
                    begin
                        read_resp <= '0;
                    end
                
                if(jalr_done)
                    begin
                        jalr_en_latch <= 1'b0;
                        read_ptr <= read_ptr + 1'b1;
                        write_ptr <= read_ptr + 1'b1;
                    end
                
                // if(flush)
                //     begin
                //         read_ptr <= '0;
                //         write_ptr <= '0;
                //     end
            end
    end


logic [$clog2(QUEUE_DEPTH)-1:0] temp;
assign temp = read_ptr-write_ptr;

always_comb
    begin
        if(read_ptr == write_ptr) // if queue is empty no more instructions to push raise flag
            begin
                queue_empty = 1'b1;
            end 
        else // if queue is empty we can keep pushing instructions
            begin
                queue_empty = 1'b0;
            end
        
        if(read_ptr == (write_ptr + 1'b1)) // if queue is empty no more instructions to push raise flag
            begin
                queue_full = 1'b1;
            end 
        else // if queue is empty we can keep pushing instructions
            begin
                queue_full = 1'b0;
            end

        // if((write_ptr < read_ptr) && (read_ptr <= (write_ptr + RD_PTR_INCR[$clog2(QUEUE_DEPTH)-1:0]))) // if queue is empty no more instructions to push raise flag
        // if((write_ptr < read_ptr) && (read_ptr-write_ptr <= RD_PTR_INCR)) // if queue is empty no more instructions to push raise flag
        //     begin
        //         queue_full_param = 1'b1;
        //     end 
        // else // if queue is empty we can keep pushing instructions
        //     begin
        //         queue_full_param = 1'b0;
        //     end

        queue_full_param = 1'b0;
        if(write_ptr < read_ptr) begin

            if((temp <= 4'd4)) begin
                queue_full_param = 1'b1;
            end

        end else if (read_ptr < write_ptr) begin

            if(temp <= 4'd4) begin
                queue_full_param = 1'b1;
            end

        end
    end



endmodule