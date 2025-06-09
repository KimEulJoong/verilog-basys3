`timescale 1ns / 1ps

module watch_DP(
    input clk,
    input rst,
    input sw2,
    input [1:0]time_select,
    input [1:0]up_down,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    wire w_tick_100, w_sec_tick, w_min_tick;

    time_couter_watch #(
        .BIT_WIDTH (7),
        .TICK_COUNT(100),
        .rst_time  (0),
        .time_sel(0)
    ) U_MSEC (
        .clk(clk),
        .rst(rst),
        .i_time_sel(time_select),
        .up_down(up_down),
        .i_tick(w_tick_100),
        .o_time(msec),
        .o_tick(w_sec_tick)
    );

    time_couter_watch #(
        .BIT_WIDTH (6),
        .TICK_COUNT(60),
        .rst_time  (0),
        .time_sel(1)
    ) U_SEC (
        .clk(clk),
        .rst(rst),
        .i_time_sel(time_select),
        .up_down(up_down),
        .i_tick(w_sec_tick),
        .o_time(sec),
        .o_tick(w_min_tick)
    );

    time_couter_watch #(
        .BIT_WIDTH (6),
        .TICK_COUNT(60),
        .rst_time  (0),
        .time_sel(2)
    ) U_min (
        .clk(clk),
        .rst(rst),
        .i_time_sel(time_select),
        .up_down(up_down),
        .i_tick(w_min_tick),
        .o_time(min),
        .o_tick(w_hour_tick)
    );

    time_couter_watch #(
        .BIT_WIDTH (5),
        .TICK_COUNT(24),
        .rst_time  (12),
        .time_sel(3)
    ) U_hour (
        .clk(clk),
        .rst(rst),
        .i_time_sel(time_select),
        .up_down(up_down),
        .i_tick(w_hour_tick),
        .o_time(hour),
        .o_tick()
    );

    tick_gen_100hz_watch U_Tick_100hz (
        .clk(clk & ~sw2),
        .rst(rst),
        .o_tick_100(w_tick_100)
    );
endmodule



module time_couter_watch #(
    parameter BIT_WIDTH = 7,
    TICK_COUNT = 100,
    rst_time = 0,
    time_sel = 0
) (
    input                        clk,
    input                        rst,
    input [1:0]                  i_time_sel,
    input [1:0]                  up_down,
    input                        i_tick,
    output wire [BIT_WIDTH -1:0] o_time,
    output                       o_tick
);

    reg [$clog2(TICK_COUNT) - 1:0] count_reg, count_next;
    reg o_tick_reg, o_tick_next;

    assign o_tick = o_tick_reg;
    assign o_time = count_reg;

    // state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count_reg  <= rst_time;
            o_tick_reg <= 0;
        end else if (i_time_sel == time_sel && up_down == 2'b10) begin
            count_reg <= count_reg +1;
        end else if (i_time_sel == time_sel && up_down == 2'b01) begin
            count_reg <= count_reg -1;
        end 
        else begin
            count_reg  <= count_next;
            o_tick_reg <= o_tick_next;
        end
    end

    // CL next state
    always @(*) begin
        count_next  = count_reg;
        o_tick_next = 1'b0;
        if (i_tick == 1'b1) begin
            if (count_reg == (TICK_COUNT - 1)) begin
                count_next  = 1'b0;
                o_tick_next = 1'b1;
            end else begin
                count_next  = count_reg + 1;
                o_tick_next = 1'b0;
            end
        end
    end

endmodule

module tick_gen_100hz_watch (
    input clk,
    input rst,
    output reg o_tick_100
);
    parameter FCOUNT = 1_000_000; //원본 1_000_000, tb:1000
    reg [$clog2(FCOUNT)-1:0] r_counter;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_counter  <= 0;
            o_tick_100 <= 0;
        end else begin
            if (r_counter == FCOUNT - 1) begin
                o_tick_100 <= 1'b1; //count 값이 일치할때, o_tick 상승승
                r_counter <= 0;
            end else begin
                o_tick_100 <= 1'b0;
                r_counter  <= r_counter + 1;
            end
        end
    end
endmodule

