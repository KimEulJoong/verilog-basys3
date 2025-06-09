`timescale 1ns / 1ps

module controll_unit (
    input         clk,
    input         rst,
    input  [ 7:0] rx_data,
    input  [ 5:0] sw,
    input         ready_flag,
    output [13:0] controll_data,
    output        dht11_start,
    output        sr04_start
);

    parameter RESET = "Q", RUN = "r", STOP = "S", CLEAR = "C", LEFT= "L", RIGHT = "R", 
                DHT11_START = "H", SR04_START = "0",
                UP = "U", DOWN = "D", MODE_CHANGE = "1" ,TIME_VIEW_CHANGE ="0", TIME_MODIFY = "2",
                DHT11="5" , SR04="4", TIME = "3" ;

    reg [13:0] controll_data_reg, controll_data_next;
    reg dht11_start_reg, dht11_start_next;
    reg sr04_reg, sr04_next;
    assign controll_data = controll_data_reg;
    assign dht11_start = dht11_start_reg;
    assign sr04_start = sr04_reg;
    /////////////////////
    reg prev_ready_flag;
    wire ready_pulse;
    assign ready_pulse = ready_flag & ~prev_ready_flag;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            controll_data_reg <= 0;
            dht11_start_reg <= 0;
            sr04_reg <= 0;
            //////////////
            prev_ready_flag <= 0;
        end else begin
            controll_data_reg <= controll_data_next;
            dht11_start_reg <= dht11_start_next;
            sr04_reg <= sr04_next;
            //////////////////////
            prev_ready_flag <= ready_flag;
        end
    end

    always @(*) begin
    controll_data_next = {controll_data_reg[13:8], 8'b0}; // 7'b0 → 8'b0로 수정
    dht11_start_next = 0;
    sr04_next = 0;
    if (ready_pulse) begin
        case (rx_data)
            DHT11_START: dht11_start_next = 1;
            SR04_START:  sr04_next = 1;
            RESET:       controll_data_next[0] = 1;
            RUN:         controll_data_next[1] = 1;
            STOP:        controll_data_next[2] = 1;
            CLEAR:       controll_data_next[3] = 1;
            LEFT:        controll_data_next[4] = 1;
            RIGHT:       controll_data_next[5] = 1;
            UP:          controll_data_next[6] = 1;
            DOWN:        controll_data_next[7] = 1;
            TIME_VIEW_CHANGE: controll_data_next[8] = ~controll_data_reg[8];
            MODE_CHANGE:      controll_data_next[9] = ~controll_data_reg[9];
            TIME_MODIFY:      controll_data_next[10] = ~controll_data_reg[10];
            TIME:             controll_data_next[11] = ~controll_data_reg[11];
            SR04:             controll_data_next[12] = ~controll_data_reg[12];
            DHT11:            controll_data_next[13] = ~controll_data_reg[13];
        endcase
    end
    if (sw) begin
        controll_data_next[13:8] = 0;
    end
end




endmodule


