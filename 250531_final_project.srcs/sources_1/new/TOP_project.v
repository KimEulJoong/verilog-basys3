`timescale 1ns / 1ps

module TOP_project (
    input clk,
    input rst,
    input echo,
    input [5:0] sw,
    input btnL,btnR,btnU,btnD,
    input rx,
    output tx,
    output trig,
    output [7:0] fnd_data,
    output [3:0] fnd_com,
    inout dht11_io
);

    wire w_ready_flag, w_dht11_start, w_sr04_start;
    wire [13:0] w_controll_data;
    wire [15:0] w_uart_send_data;
    wire [ 7:0] w_rx_pop_data;
    wire [15:0] w_CU_data = {w_dht11_start, w_sr04_start, w_controll_data};

    sender_uart U_UART_SEND (
        .clk        (clk),
        .rst        (rst),
        .rx         (rx),
        .sw         (sw[5:4]),
        .i_send_data(w_uart_send_data),  // 15:0
        .btn_start  (btnU),
        .tx         (tx),
        .tx_done    (),
        .rx_pop_data(w_rx_pop_data),     // 7:0
        .ready_flag (w_ready_flag)
    );

    controll_unit U_CNTL_UNIT (
        .clk          (clk),
        .rst          (rst),
        .rx_data      (w_rx_pop_data),    //7:0
        .sw           (sw),               //[3:0] sw
        .ready_flag   (w_ready_flag),
        .controll_data(w_controll_data),  // 10:0
        .dht11_start  (w_dht11_start),
        .sr04_start   (w_sr04_start)
    );

    TOP_CNTR U_TOP_CNTL (
        .clk(clk),
        .rst(rst), // w_controll_data[0]
        .cu_data(w_CU_data),
        .sw0(sw[0]),  // 시간모드 바꾸기
        .sw1(sw[1]),  // 0:시계, 1: 스톱워치
        .sw2(sw[2]),  // blink
        .sw13(sw[3]), //시계
        .sw14(sw[4] | w_CU_data[12]), // 초음파
        .sw15(sw[5] | w_CU_data[13]), // 온습도
        .btnL(btnL),  // 시계: msec/min, 스톱워치: run_stop
        .btnR(btnR),  // 시계: sec/hour, 스톱워치: clear
        .btnU(btnU),  // 시계: 선택시간+1
        .btnD(btnD),  // 시계: 선택시간-1
        .echo(echo),  //sr04
        .dht11_io(dht11_io),  //dht11
        .trig(trig),  //sr04
        .fnd_com(fnd_com),
        .fnd_data(fnd_data),
        .uart_send_data(w_uart_send_data)
    );

endmodule
