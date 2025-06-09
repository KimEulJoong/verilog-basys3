`timescale 1ns / 1ps

module Top_watch(
    input clk,
    input rst,
    input [15:0]cu_data,
    input sw0, //시간모드 바꾸기
    input sw1, // 0:시계, 1: 스톱워치
    input sw2, //blink
    input btnL, //시계: msec/min, 스톱워치: run_stop
    input btnR, // 시계 :sec/hour, 스톱워치: clear
    input btnU, // 시계: 선택시간+1
    input btnD, // 시계: 선택시간-1
    output [23:0]time_data
    //output [3:0] led
    );
    wire [6:0]w_msec;
    wire[5:0] w_sec;
    wire[5:0] w_min;
    wire[4:0] w_hour;
    //wire w_claer, w_runstop;
    wire [3:0] w_btn ={btnD, btnU, btnR, btnL};
    wire [3:0] w_btn_stop_watch, w_btn_watch;
    wire [23:0] w_time_SW, w_time_W, w_time_data;
    wire [1:0] w_sw = {sw1, sw0};

    assign time_data = w_time_data;

    // LED_state U_LED_STATE(
    //     .sw(w_sw),
    //     .LED(led)
    // );

    DEMUX_1X2_watch U_DEMUX_1X2_W(
    .btn(w_btn),
    .sw_stopW_watch(sw1|cu_data[9]),
    .o_btn_stop_watch(w_btn_stop_watch),
    .o_btn_watch(w_btn_watch)
    );

    watch U_WATCH (
    .clk(clk),
    .rst(rst),
    //.i_com_data(i_com_data),
    .sw2(sw2), //blink
    .btnL(w_btn_watch[0] | cu_data[4]),
    .btnR(w_btn_watch[1] | cu_data[5]),
    .btnU(w_btn_watch[2] | cu_data[6]),
    .btnD(w_btn_watch[3] | cu_data[7]),
    .sw_time_mode(sw0|cu_data[11]),
    .time_data(w_time_W)
); 

    stop_watch U_STOP_WATCH (
    .clk(clk),
    .rst(rst),
    .i_com_data(),
    .btnL(w_btn_stop_watch[0]|cu_data[4]),
    .btnR(w_btn_stop_watch[1]|cu_data[5]),
    .time_data(w_time_SW)
); 
    mux2x1_watch U_MUX2X1_w(
        .time_SW(w_time_SW),
        .time_W(w_time_W),
        .sw_stopW_watch(sw1|cu_data[9]),
        .time_data(w_time_data)
    );
endmodule

module DEMUX_1X2_watch (
    input [3:0] btn,
    input sw_stopW_watch,
    output [3:0] o_btn_watch,
    output [3:0] o_btn_stop_watch
);
    //assign btn = (sw_stopW_watch) ? o_btn_stop_watch : o_btn_watch;
    assign o_btn_stop_watch = (sw_stopW_watch) ? btn : 4'b0; 
    assign o_btn_watch      = (sw_stopW_watch) ? 4'b0 : btn; 

endmodule

module mux2x1_watch (
    input [23:0] time_SW,
    input [23:0] time_W,
    input        sw_stopW_watch,
    output [23:0] time_data   
);
    assign time_data = (sw_stopW_watch) ? time_SW :time_W;
    
endmodule

module watch (
    input clk,
    input rst,
    //input [9:0]i_com_data,
    input sw2, //blink
    input btnL,
    input btnR,
    input btnU,
    input btnD,
    input sw_time_mode,
    output [23:0] time_data
);
    wire [1:0] w_time_sel, w_up_down;
    wire [6:0]w_msec;
    wire[5:0] w_sec;
    wire[5:0] w_min;
    wire[4:0] w_hour;

    assign time_data = {w_hour,w_min,w_sec,w_msec};

     watch_CU U_WATCH_CU(
        .clk(clk),
        .rst(rst),
        //.i_com_data(i_com_data),
        .i_btnL(btnL),
        .i_btnR(btnR),
        .i_btnU(btnU),
        .i_btnD(btnD),
        .sw_time_mode(sw_time_mode),
        .time_select(w_time_sel),
        .up_down(w_up_down)
    );

    watch_DP U_WATCH_DP(
        .clk(clk),
        .rst(rst),
        .sw2(sw2), //blink
        .time_select(w_time_sel),
        .up_down(w_up_down),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour)
    );
endmodule

module stop_watch (
    input clk,
    input rst,
    input [9:0]i_com_data,
    input btnL,
    input btnR,
    input sw_time_mode,
    output [23:0] time_data
);
    wire w_claer, w_runstop;
    wire [6:0]w_msec;
    wire[5:0] w_sec;
    wire[5:0] w_min;
    wire[4:0] w_hour;

    assign time_data = {w_hour,w_min,w_sec,w_msec};

    stopwatch_CU U_STOPWATCH_CU(
        .clk(clk),
        .rst(rst),
        .i_com_data(i_com_data),
        .i_clear(btnL),
        .i_runstop(btnR),
        .o_claer(w_claer),
        .o_runstop(w_runstop)
    );

     stoop_watch_dp U_STOPWATCH_DP(
        .clk(clk),
        .rst(rst),
        .run_stop(w_runstop),
        .clear(w_claer),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour)
    );
    
endmodule
