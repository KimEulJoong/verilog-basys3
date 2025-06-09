`timescale 1ns / 1ps

module top_fnd_sr04 (
    input clk,
    input rst,
    input start,
    input echo,
    output trig,
    output [7:0] fnd_data,
    output [3:0] fnd_com

);
    wire [9:0] w_dist;
    wire [3:0] w_distance_dot;
    //wire w_dist_done;
    sr04_controller U_sr04_controller (
        .clk(clk),
        .rst(rst),
        .start(start),
        .echo(echo),
        .trig(trig),
        .dist(w_dist),
        .distance_dot(w_distance_dot),
        .dist_done()
    );
    fnd_controller U_fnd_controller (
        .clk(clk),
        .reset(rst),
        .dist_dot(w_distance_dot),
        .dist(w_dist),
        .fnd_data(fnd_data),
        .fnd_com(fnd_com)
    );
endmodule
