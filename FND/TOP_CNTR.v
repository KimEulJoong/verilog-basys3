`timescale 1ns / 1ps

module TOP_CNTR(
    input clk,
    input rst,
    input [15:0] cu_data,
    input sw0,  // 시간모드 바꾸기
    input sw1,  // 0:시계, 1: 스톱워치
    input sw2,  // blink
    input sw13,
    input sw14,
    input sw15,
    input btnL,  // 시계: msec/min, 스톱워치: run_stop
    input btnR,  // 시계: sec/hour, 스톱워치: clear
    input btnU,  // 시계: 선택시간+1
    input btnD,  // 시계: 선택시간-1
    input echo, //sr04
    inout dht11_io, //dht11
    output trig, //sr04
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output [15:0] uart_send_data
    );

    wire [23:0] w_data;
    wire [2:0] w_sel_sw;
    wire [23:0] w_time_data;
    wire [3:0] w_dist_dot;
    wire [9:0] w_dist;
    wire [13:0] w_sr04;
    wire [7:0] w_rh_data, w_t_data;
    wire [15:0] w_dht11;
    
    assign w_sel_sw = {sw15,sw14,sw13};
    assign w_sr04 = {w_dist,w_dist_dot};
    assign w_dht11 = {w_rh_data,w_t_data};
    
    fnd_controller U_FND_CNTL (
    .clk(clk),
    .reset(rst ), // | cu_data[0]
    .cu_data(cu_data),
    .sw_mode(sw0), // |cu_data[8]
    .sw1(sw1),// |cu_data[9]
    .sw2(sw2), // blink |cu_data[10]
    .sel_sw(w_sel_sw), // |cu_data[14:12]
    .data(w_data),
    .fnd_data(fnd_data),
    .fnd_com(fnd_com),
    .uart_send_data(uart_send_data)
    );

    MUX_3X1_1 U_MUX_3X1_1(
        .time_data(w_time_data),
        .sr04_data(w_sr04),
        .dht11_data(w_dht11),
        .sel(w_sel_sw), // |cu_data[14:12]
        .o_data(w_data)
    );
    Top_watch U_TOP_WATCH(
    .clk(clk),
    .rst(rst | cu_data[0]), //| cu_data[0]
    .cu_data(cu_data),
    .sw0(sw0), //시간모드 바꾸기
    .sw1(sw1), // 0:시계, 1: 스톱워치
    .sw2(sw2), //blink
    .btnL(w_btnL), //시계: msec/min, 스톱워치: run_stop
    .btnR(w_btnR), // 시계 :sec/hour, 스톱워치: clear
    .btnU(w_btnU), // 시계: 선택시간+1
    .btnD(w_btnD), // 시계: 선택시간-1
    .time_data(w_time_data)
    //.led()
    );
    sr04_controller U_SR04_CONTROLLER (
        .clk(clk),
        .rst(rst),
        .start(w_btnU | cu_data[6]), // | cu_data[6]
        .echo(echo), 
        .trig(trig),
        .dist(w_dist),
        .distance_dot(w_dist_dot),
        .dist_done()
    );
    dht11_controller U_DHT11_CONTROLLER (
        .clk(clk),
        .rst(rst),
        .start(w_btnU | cu_data[6]), // | cu_data[6]
        .rh_data(w_rh_data),
        .t_data(w_t_data),
        .dht11_done(),
        .dht11_valid(),
        .state_led(),
        .valid_led(),
        .dht11_io(dht11_io)  
    );


    btn_debounce U_BTN_DEBOUNCE_UP (
        .clk(clk),
        .rst(rst),
        .i_btn(btnU),
        .o_btn(w_btnU)  
    );
    btn_debounce U_BTN_DEBOUNCE_DOWN (
        .clk(clk),
        .rst(rst),
        .i_btn(btnD),
        .o_btn(w_btnD)  
    );
    btn_debounce U_BTN_DEBOUNCE_LEFT (
        .clk(clk),
        .rst(rst),
        .i_btn(btnL),
        .o_btn(w_btnL)  
    );
    btn_debounce U_BTN_DEBOUNCE_RIGHT (
        .clk(clk),
        .rst(rst),
        .i_btn(btnR),
        .o_btn(w_btnR)  
    );
endmodule

module MUX_3X1_1 (
    input [23:0] time_data,
    input [15:0] sr04_data,
    input [13:0] dht11_data,
    input [2:0] sel,
    output reg [23:0] o_data
);

always @(*) begin
    o_data = 0;
    case (sel)
        3'b001: o_data = time_data;
        3'b010: o_data = sr04_data;
        3'b100: o_data = dht11_data;
        default: o_data = 0;
    endcase
end
    
endmodule
