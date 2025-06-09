`timescale 1ns / 1ps

module uart_controller (
    input        clk,
    input        rst,
    input        rx,
    input        tx_push,       // 
    input  [7:0] tx_push_data,
    input        rx_pop,
    output       tx,
    output       rx_done,
    output       rx_empty,
    output       tx_full,
    output [7:0] rx_pop_data,
    output       tx_done,
    output       tx_busy,
    output       ready_flag
);

    wire [7:0] w_rx_data, w_pop_data, w_push_data;
    wire w_rx_done, w_tx_busy, w_empty, w_tx_start, w_full;

    wire w_bd_tick;
    wire w_btn_start;
    assign rx_done = w_rx_done;
    assign tx_busy = w_tx_busy;


    uart_tx U_UART_TX (
        .clk      (clk),
        .rst      (rst),
        .baud_tick(w_bd_tick),
        .start    (~w_tx_start),
        .data_in  (w_pop_data),
        .o_tx     (tx),
        .o_tx_busy(w_tx_busy),
        .o_tx_done(tx_done)
    );

    uart_rx U_UART_RX (
        .clk      (clk),
        .rst      (rst),
        .rx       (rx),
        .b_tick   (w_bd_tick),
        .o_dout   (w_rx_data),
        .o_rx_done(w_rx_done)
    );

    fifo U_TX_FIFO (
        .clk       (clk),
        .rst       (rst),           //controll block reset용
        .push      (tx_push),       //
        .pop       (~w_tx_busy),
        .push_data (tx_push_data),  //[7:0] push
        .full      (tx_full),       // tx fifo full
        .empty     (w_tx_start),
        .pop_data  (w_pop_data),    // [7:0]
        .ready_flag()
    );

    fifo U_RX_FIFO (
        .clk       (clk),
        .rst       (rst),          //controll block reset용
        .push      (w_rx_done),
        .pop       (~rx_empty),    //rx_pop   //rx fifo pop
        .push_data (w_rx_data),    //[7:0] from tx fifo
        .full      (),             //don't use
        .empty     (rx_empty),     // rx fifo empty
        .pop_data  (rx_pop_data),  // pop data [7:0]
        .ready_flag(ready_flag)
    );

    baudrate U_BR (
        .clk(clk),
        .rst(rst),
        .baud_tick(w_bd_tick)
    );
endmodule
