`timescale 1ns / 1ps
/*
module baudrate (
    input  clk,
    input  rst,
    input [16:0] baud_rate,
    output baud_tick,
    output baud_tick_x8
);

    // 입력 clk 100Mhz
    parameter BAUD = 115200;
    parameter BAUD_COUNT_DEFAULT = 100000000 / BAUD;
    wire [16:0] baud_count;

    reg baud_tick_reg, baud_tick_next,baud_tick_x8_reg,baud_tick_x8_next;
    //reg  [$clog2(BAUD_COUNT)-1:0] count_reg;
    //wire [$clog2(BAUD_COUNT)-1:0] count_next;  // 피드백 구조
    reg [19:0] count_reg, count_next;

    //assign count_next = (count_reg == BAUD_COUNT - 1) ? 0 : count_reg + 1;
    //assign baud_tick  = (count_reg == BAUD_COUNT - 1) ? 1'b1 : 1'b0;
    assign baud_tick = baud_tick_reg;
    assign baud_count = 100_000_000/baud_rate;
    assign baud_tick_x8 = baud_tick_x8_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count_reg     <= 0;
            baud_tick_reg <= 0;
            baud_tick_x8_reg <= 0;
        end else begin
            count_reg      <= count_next;
            baud_tick_reg <= baud_tick_next;
            baud_tick_x8_reg <= baud_tick_x8_next;
        end
    end
    
    always @(*) begin
        count_next = count_reg;
        baud_tick_next = 1'b0;      // baud_tick_reg 로 써도됨. 틱 체크가 아니라 틱 생성이기 때문에
        baud_tick_x8_next = baud_tick_x8_reg;
        if (count_reg == baud_count - 1) begin
            count_next = 0;
            baud_tick_next = 1'b1;
            baud_tick_x8_next = 1'b1;
        end else if((count_reg % (baud_count/8))==0) begin
            count_next = count_reg + 1;
            baud_tick_next = 1'b0;
            baud_tick_x8_next = 1'b1;
        end else begin
            count_next = count_reg + 1;
            baud_tick_next = 1'b0;
            baud_tick_x8_next = 1'b0;
        end
    end
endmodule
*/
module baudrate (
    input  clk,
    input  rst,
    output baud_tick
);

    // 입력 clk 100Mhz
    parameter BAUD = 9600;
    parameter BAUD_COUNT = 100000000/(BAUD*8);
    reg  [$clog2(BAUD_COUNT)-1:0] count_reg, count_next;


    reg baud_tick_reg, baud_tick_next;
   
    //assign count_next = (count_reg == BAUD_COUNT - 1) ? 0 : count_reg + 1;
    //assign baud_tick  = (count_reg == BAUD_COUNT - 1) ? 1'b1 : 1'b0;
    assign baud_tick = baud_tick_reg;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count_reg     <= 0;
            baud_tick_reg <= 0;
        end else begin
            count_reg      <= count_next;
            baud_tick_reg <= baud_tick_next;
        end
    end
    
    always @(*) begin
        count_next = count_reg;
        baud_tick_next = 1'b0;      // baud_tick_reg 로 써도됨. 틱 체크가 아니라 틱 생성이기 때문에
        if (count_reg == BAUD_COUNT - 1) begin
            count_next = 0;
            baud_tick_next = 1'b1;
        end  else begin
            count_next = count_reg + 1;
            baud_tick_next = 1'b0;
        end
    end

endmodule
