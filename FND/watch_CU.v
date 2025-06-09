`timescale 1ns / 1ps


module watch_CU(
input clk,
input rst,
//input [9:0]i_com_data,
input i_btnL,
input i_btnR,
input i_btnU,
input i_btnD,
input sw_time_mode,
output [1:0]time_select,
output [1:0]up_down 
    );

    parameter TIME_msec =0, TIME_sec =1, TIME_min=2,TIME_hour=3;
    //parameter TIME_UP =4, TIME_DOWN = 5;
    reg [1:0] c_state, n_state;

    //  assign time_select = (c_state == TIME_msec) ? 1:0;
    //  assign up_down = (i_btnU == 1) ? 1:0;
    assign time_select = c_state;
    assign up_down = {i_btnU,i_btnD};

    //SL state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <=0;
        end else begin
            c_state <= n_state;
        end
    end

    always @(*) begin
        n_state = c_state;
        case (c_state)
            TIME_msec: begin
                if (i_btnL==1 && sw_time_mode ==0) begin
                    n_state = TIME_sec;
                end else if (i_btnL==0 && sw_time_mode == 1) begin
                    n_state = TIME_min;
                end
            end 
            TIME_sec: begin
                if (i_btnR==1 && sw_time_mode ==0) begin
                    n_state =TIME_msec;
                end else if (sw_time_mode == 1) begin
                    n_state = TIME_min;
                end
            end
            TIME_min: begin
                if (i_btnL ==1 && sw_time_mode == 1) begin
                    n_state=TIME_hour;
                end else if (sw_time_mode == 0) begin
                    n_state = TIME_msec;
                end
            end
            TIME_hour: begin
                if (i_btnR ==1 && sw_time_mode == 1) begin
                    n_state=TIME_min;
                end else if (sw_time_mode == 0) begin
                    n_state = TIME_msec;
                end
            end
        endcase
    end

endmodule

