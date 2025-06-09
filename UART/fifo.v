`timescale 1ns / 1ps


module fifo (
    input        clk,
    input        rst,        //controll block reset용
    input        push,
    input        pop,
    input  [7:0] push_data,
    output       full,
    output       empty,
    output [7:0] pop_data,
    output ready_flag
);

    wire [3:0] w_w_ptr, w_r_ptr;
    wire w_full;
    assign full=w_full;

    register_file U_REG (
        .clk  (clk),
        .wr_en(push&(~w_full)),
        .wdata(push_data),
        .w_ptr(w_w_ptr),
        .r_ptr(w_r_ptr),
        .rdata(pop_data)
    );

    fifo_cu U_FIFO (
        .clk  (clk),
        .rst  (rst),
        .push (push),
        .pop  (pop),
        .w_ptr(w_w_ptr),
        .r_ptr(w_r_ptr),
        .full (w_full),
        .empty(empty),
        .ready_flag(ready_flag)
    );
endmodule


module register_file #(
    parameter DEPTH = 16,
    WIDTH = 4
) (
    input              clk,
    input              wr_en,  // write enable
    input  [      7:0] wdata,
    input  [WIDTH-1:0] w_ptr,  // write address
    input  [WIDTH-1:0] r_ptr,  // read address
    output [      7:0] rdata
);

    reg [7:0] mem[0:DEPTH-1];  //mem[0:2**WIDTH -1], **:제곱

    assign rdata = mem[r_ptr];    // clk마다 출력이 아닌 출력 상태 유지.

    always @(posedge clk) begin
        if (wr_en) begin
            mem[w_ptr] <= wdata;
        end
        //rdata <= mem[r_ptr];          // 매 clk마다 mem data를 내보낸다.
    end
endmodule

module fifo_cu (
    input clk,
    input rst,
    input push,
    input pop,
    output [3:0] w_ptr,
    output [3:0] r_ptr,
    output full,
    output empty,
    output ready_flag
);

    // State 만들지 않고 진행

    reg [3:0] w_ptr_reg, w_ptr_next, r_ptr_reg, r_ptr_next;
    reg full_reg, full_next, empty_reg, empty_next;
    reg ready_reg, ready_next;
    ////////////
    // reg pop_d, pop_edge, ready_flag_reg;//


    assign full = full_reg;
    assign empty = empty_reg;
    assign w_ptr = w_ptr_reg;
    assign r_ptr = r_ptr_reg;
    assign ready_flag = ready_reg;

    // assign ready_flag = ready_flag_reg; //



    always @(posedge clk, posedge rst) begin
        if (rst) begin
            w_ptr_reg <= 0;
            r_ptr_reg <= 0;
            full_reg  <= 0;
            empty_reg <= 1;
            ready_reg <= 0;
            ///////////
            // pop_d <= 0;
            // pop_edge <= 0;
            // ready_flag_reg <= 0;
        end else begin
            w_ptr_reg <= w_ptr_next;
            r_ptr_reg <= r_ptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
            ///////////////////////
            // pop_d <= pop;
            // pop_edge <= (pop && ~pop_d) && !empty;
            // ready_flag_reg <= pop_edge;
            ////////////////
            if (push && !full) begin
                ready_reg <=1;
            end else begin
                ready_reg <=0;
            end
        end
    end

    always @(*) begin
        w_ptr_next = w_ptr_reg;
        r_ptr_next = r_ptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;
        ready_next = 0;
        case ({
            pop, push
        })  // 2b로 결합
            2'b01: begin  //push
                if (full_reg == 0) begin
                    w_ptr_next = w_ptr_reg + 1;
                    empty_next = 0;
                    ready_next = 1;
                    if (w_ptr_next == r_ptr_reg) begin
                        full_next = 1;
                    end
                end
            end
            2'b10: begin  //pop
                if (empty_reg == 0) begin
                    r_ptr_next = r_ptr_reg + 1;
                    full_next  = 0;
                    if (r_ptr_next == w_ptr_reg) begin
                        empty_next = 1;
                    end
                end
            end
            2'b11: begin  //push,pop 같이 들어올 때, 우선 순위 필요 
                if (empty_reg == 1) begin
                    w_ptr_next = w_ptr_reg + 1;
                    empty_next = 0;
                end else if (full_reg == 1) begin
                    r_ptr_next = r_ptr_reg + 1;
                    full_next  = 0;
                end else begin
                    w_ptr_next = w_ptr_reg + 1;
                    r_ptr_next = r_ptr_reg + 1;
                    
                end
            end
        endcase
    end

endmodule
