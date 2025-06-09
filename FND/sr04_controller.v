`timescale 1ns / 1ps

module sr04_controller (
    input clk,
    input rst,
    input start,
    input echo,
    output trig,
    output [9:0] dist,
    output [3:0] distance_dot,
    output dist_done
);

    wire w_tick;

    start_trigger U_Start_Trigger (
        .clk(clk),
        .rst(rst),
        .i_tick(w_tick),
        .start(start),
        .o_sr04_trigger(trig)
    );
    tick_gen_1Mhz U_Tick_Gen (
        .clk(clk),
        .rst(rst),
        .o_tick_1mhz(w_tick)
    );

    distance U_Distance (
        .clk(clk),
        .rst(rst),
        .echo(echo),
        .i_tick(w_tick),
        .distance(dist),
        .distance_dot(distance_dot),
        .dist_done(dist_done)
    );
endmodule

module distance (
    input clk,
    input rst,
    input echo,
    input i_tick,
    output [9:0] distance,
    output [3:0] distance_dot,
    output dist_done
);
    reg [17:0] count_reg, count_next; //[$clog2(500*58)-1:0] = 17 bits for 500ms at 1MHz
    reg dist_done_reg, dist_done_next;

    assign dist_done = dist_done_reg;
    assign distance = (dist_done_reg ==1) ? count_reg/58: 0;
    assign distance_dot = (dist_done_reg == 1) ? ((count_reg % 58)*10)/58 : 0;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count_reg <= 0;
            dist_done_reg <= 0;
        end else begin
            count_reg <= count_next;
            dist_done_reg <= dist_done_next;
        end
    end

    always @(*) begin
        count_next = count_reg;
        dist_done_next = dist_done_reg;
        case (echo)
            0: begin
                count_next = count_reg;
                dist_done_next = 1;
            end
            1: begin
                if (dist_done_reg == 1) begin
                    count_next = 0;
                    dist_done_next = 0;
                end
                else if (i_tick) begin
                    count_next = count_reg + 1;
                end
            end
        endcase
    end

endmodule

module start_trigger (
    input  clk,
    input  rst,
    input  i_tick,
    input  start,
    output o_sr04_trigger
);

    reg start_reg, start_next;
    reg sr04_trigg_reg, sr04_trigg_next;
    reg [3:0] count_reg, count_next;

    assign o_sr04_trigger = sr04_trigg_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            start_reg <= 0;
            sr04_trigg_reg <= 0;
            count_reg <= 0;
        end else begin
            start_reg <= start_next;
            sr04_trigg_reg <= sr04_trigg_next;
            count_reg <= count_next;
        end
    end

    always @(*) begin
        start_next = start_reg;
        sr04_trigg_next = sr04_trigg_reg;
        count_next = count_reg;

        case (start_reg)
            0: begin
                count_next = 0;
                sr04_trigg_next = 0;
                if (start) begin
                    start_next = 1;
                end
            end
            1: begin
                if (i_tick) begin
                    sr04_trigg_next = 1;
                    count_next = count_reg + 1;
                    if (count_reg == 10) begin
                        start_next = 0;
                    end
                end
            end
        endcase
    end

endmodule

module tick_gen_1Mhz (
    input  clk,
    input  rst,
    output o_tick_1mhz
);
    parameter F_COUNT = (100 - 1);

    reg [6:0] count;
    reg tick;

    assign o_tick_1mhz = tick;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count <= 0;
            tick  <= 0;
        end else begin
            if (count == F_COUNT) begin
                count <= 0;
                tick  <= 1'b1;
            end else begin
                count <= count + 1;
                tick  <= 1'b0;
            end
        end
    end



endmodule
