`timescale 1ns / 1ps


module stopwatch_CU(
input clk,
input rst,
input [9:0]i_com_data,
input i_clear,
input i_runstop,
output  o_claer,
output  o_runstop
    );

    parameter STOP =0, RUN =1, CLEAR =2;

    reg [1:0] c_state, n_state;
    // reg run_stop_reg, run_stop_next;
    // reg claer_reg, claer_next;

     assign o_claer = (c_state == CLEAR) ? 1:0;
     assign o_runstop = (c_state == RUN) ? 1:0;

    //SL state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <=0;
            // o_claer <= 0;
            // o_runstop <=0;
        end else begin
            c_state <= n_state;
        end
    end

    always @(*) begin
        n_state = c_state;
        case (c_state)
            STOP: begin
                if (i_runstop || i_com_data[0] ) begin
                    n_state = RUN;
                end else if (i_clear || i_com_data[2]) begin
                    n_state = CLEAR;
                end else n_state = c_state;
            end 
            RUN: begin
                if (i_runstop || i_com_data[1]) begin
                    n_state =STOP;
                end
            end
            CLEAR: begin
                if (i_clear || i_com_data[2]) begin
                    n_state=STOP;
                end
            end
        endcase
    end

endmodule
