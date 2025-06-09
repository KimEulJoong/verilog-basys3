`timescale 1ns / 1ps
module sender_uart (

    input clk,
    input rst,
    input rx,
    input [1:0] sw,
    input [15:0] i_send_data,
    input btn_start,
    output tx,
    output tx_done,
    output [7:0] rx_pop_data,
    output ready_flag
);

    wire w_start, w_tx_full;
    wire [31:0] w_send_data;
    reg c_state, n_state;
    reg [7:0] send_data_reg, send_data_next;
    reg send_reg, send_next;
    reg [4:0] send_cnt_reg, send_cnt_next;

    btn_debounce U_START_BD (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_start),
        .o_btn(w_start)
    );

    //    assign w_start = btn_start;

    uart_controller U_UART_CNTL (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .rx_pop(), //
        .tx_push_data(send_data_reg),
        .tx_push(send_reg),
        .rx_pop_data(rx_pop_data),
        .rx_empty(),
        .rx_done(),
        .tx_full(w_tx_full),
        .tx_done(tx_done),
        .tx_busy(),
        .tx(tx),
        .ready_flag(ready_flag)
    );

    datatoascii U_DtoA (
        .i_data(i_send_data),
        .o_data(w_send_data)
    );

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state       <= 0;
            send_data_reg <= 0;
            send_reg      <= 0;
            send_cnt_reg  <= 0;
        end else begin
            c_state       <= n_state;
            send_data_reg <= send_data_next;
            send_reg      <= send_next;
            send_cnt_reg  <= send_cnt_next;
        end
    end

    always @(*) begin
        n_state        = c_state;
        send_data_next = send_data_reg;
        send_next      = send_reg;
        send_cnt_next  = send_cnt_reg;
        case (c_state)
            00: begin
                send_cnt_next = 0;
                if (w_start) begin
                    n_state = 1;
                end
            end
            01: begin  // send
                if (~w_tx_full) begin
                    send_next = 1;  // send tick 생성.
                    if (sw==1) begin
                        // 상위부터 보내기
                        case (send_cnt_reg)
                            0: send_data_next = 8'h44;
                            1: send_data_next = 8'h49;
                            2:send_data_next = 8'h53;
                            3: send_data_next = 8'h54;
                            4:send_data_next = 8'h41;
                            5:send_data_next = 8'h4E;
                            6:send_data_next = 8'h43;
                            7:send_data_next = 8'h45;
                            8:send_data_next = 8'h3A;
                            9:send_data_next = w_send_data[31:24];
                            10:send_data_next = w_send_data[23:16];
                            11:send_data_next = w_send_data[15:8];
                            12:send_data_next = 8'h2E;
                            13:send_data_next = w_send_data[7:0];
                            14:send_data_next = 8'h63;
                            15:send_data_next = 8'h6D;
                            16: send_data_next = 8'h0A;
                            17: begin
                                n_state   = 0;
                                send_next = 0;
                            end
                        endcase
                        send_cnt_next = send_cnt_reg + 1;
                    end else if (sw==2) begin
                        case (send_cnt_reg)                                                     
                            1: send_data_next = 8'h52;
                            2: send_data_next = 8'h48;
                            3: send_data_next = 8'h3A;
                            4: send_data_next = w_send_data[31:24];
                            5: send_data_next = w_send_data[23:16];
                            6: send_data_next = 8'h25;
                            7: send_data_next = 8'h2C;
                            8: send_data_next = 8'h54;
                            9:  send_data_next = 8'h45;
                            10:  send_data_next = 8'h4D;
                            11:  send_data_next = 8'h50;
                            12:  send_data_next = 8'h3A;
                            13: send_data_next = w_send_data[15:8];
                            14: send_data_next = w_send_data[7:0];
                            15: send_data_next = 8'h27;
                            16: send_data_next = 8'h43;
                            17: send_data_next = 8'h0A;
                            18: begin
                                n_state   = 0;
                                send_next = 0;
                            end
                        endcase
                        send_cnt_next = send_cnt_reg + 1;
                    end else begin
                        n_state = c_state;
                    end
                end else n_state = c_state;
            end
        endcase
    end
endmodule

// decoder, LUT
module datatoascii (
    input  [15:0] i_data,
    output [31:0] o_data
);
    assign o_data[7:0]   = i_data[3:0] + 8'h30;  // 나머지 + 8'h30
    assign o_data[15:8]  = i_data[7:4] + 8'h30;
    assign o_data[23:16] = i_data[11:8] + 8'h30;
    assign o_data[31:24] = i_data[15:12] + 8'h30;
endmodule