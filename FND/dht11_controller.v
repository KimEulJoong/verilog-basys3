`timescale 1ns / 1ps
module dht11_controller (
    input        clk,
    input        rst,
    input        start,
    output [4:0] state_led,
    output       valid_led,
    output [7:0] rh_data,
    output [7:0] t_data,
    output       dht11_done,
    output       dht11_valid,
    inout        dht11_io
);

    wire w_tick;

    tick_gen_10um U_TICK_GEN (
        .clk(clk),
        .rst(rst),
        .o_tick(w_tick)
    );

    parameter IDLE = 0, START = 1, WAIT = 2, SYNCL=3, SYNCH = 4, DATA_SYNC = 5, DATA_DETECT = 6, DATA_COMPARE = 7, STOP = 8;

    reg [4:0] c_state, n_state;
    reg [$clog2(1900)-1:0] t_cnt_reg, t_cnt_next;
    reg dht11_reg, dht11_next;
    reg [6:0] data_cnt_reg, data_cnt_next;
    reg io_en_reg, io_en_next;

    assign dht11_io = (io_en_reg) ? dht11_reg : 1'bz;

    reg edge_dht11_io;

    reg flag_reg, flag_next;

    reg [39:0] data_reg, data_next;
    reg
        valid_reg,
        valid_next;  // check sum 이 맞으면 valid_reg = 1 틀리면 0
    assign rh_data = data_reg[39:32];
    assign t_data = data_reg[23:16];
    assign dht11_valid = valid_reg;  // check sum
    assign state_led = c_state;
    assign valid_led = valid_reg;

    wire [7:0] sum0 = data_reg[39:32];
    wire [7:0] sum1 = data_reg[31:24];
    wire [7:0] sum2 = data_reg[23:16];
    wire [7:0] sum3 = data_reg[15:8];
    wire [7:0] lsb = data_reg[7:0];
    wire [7:0] total_sum = sum0 + sum1 + sum2 + sum3;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state      <= 0;
            t_cnt_reg    <= 0;
            dht11_reg    <= 1;  // 초기값 항상 High로.
            io_en_reg    <= 1;  // IDLE에서 항상 출력 Mode
            valid_reg    <= 0;
            data_reg     <= 0;
            data_cnt_reg <= 0;
            flag_reg     <= 0;
        end else begin
            c_state       <= n_state;
            t_cnt_reg     <= t_cnt_next;
            dht11_reg     <= dht11_next;
            io_en_reg     <= io_en_next;
            valid_reg     <= valid_next;
            data_reg      <= data_next;
            data_cnt_reg  <= data_cnt_next;
            edge_dht11_io <= dht11_io;
            flag_reg      <= flag_next;
        end
    end

    wire u_edge_dht11_io = ((dht11_io == 1) && (edge_dht11_io == 0));
    wire d_edge_dht11_io = ((dht11_io == 0) && (edge_dht11_io == 1));


    always @(*) begin
        n_state = c_state;
        t_cnt_next = t_cnt_reg;
        dht11_next = dht11_reg;
        data_next = data_reg;
        valid_next = valid_reg;
        io_en_next = io_en_reg;
        data_cnt_next = data_cnt_reg;
        flag_next = flag_reg;
        if (total_sum == lsb) begin
            valid_next = 1'b1;
        end else begin
            valid_next = 1'b0;
        end


        case (c_state)
            IDLE: begin
                dht11_next = 1'b1;
                io_en_next = 1'b1;
                data_cnt_next = 0;
                if (start) begin
                    n_state = START;
                end
            end
            START: begin
                if (w_tick) begin
                    dht11_next = 1'b0;
                    if (t_cnt_reg == 1900) begin
                        t_cnt_next = 0;
                        n_state = WAIT;
                    end else begin
                        t_cnt_next = t_cnt_reg + 1;
                    end
                end
            end
            WAIT: begin
                //출력 High
                dht11_next = 1'b1;
                if (w_tick) begin
                    if (t_cnt_reg == 2) begin
                        t_cnt_next = 0;
                        io_en_next = 1'b0;
                        n_state = SYNCL;
                        // 입력으로 전환
                    end else begin
                        t_cnt_next = t_cnt_reg + 1;
                    end
                end
            end

            SYNCL: begin
                if (w_tick) begin
                    if (t_cnt_reg == 2) begin
                        flag_next = 1;
                    end else begin
                        t_cnt_next = t_cnt_reg + 1;
                    end
                end

                if (flag_reg) begin
                    if (dht11_io) begin
                        t_cnt_next = 0;
                        flag_next = 0;
                        n_state = SYNCH;
                    end
                end
            end
            SYNCH: begin
                if (w_tick) begin
                    if (t_cnt_reg == 2) begin
                        flag_next = 1;
                    end else begin
                        t_cnt_next = t_cnt_reg + 1;
                    end
                end

                if (flag_reg) begin
                    if (!dht11_io) begin
                        t_cnt_next = 0;
                        flag_next = 0;
                        n_state = DATA_SYNC;
                    end
                end
            end

            DATA_SYNC: begin
                if (w_tick) begin
                    if (dht11_io) begin
                        n_state = DATA_DETECT;
                    end
                end
            end
            DATA_DETECT: begin
                if (w_tick) begin
                    if (!dht11_io) begin
                        n_state = DATA_COMPARE;
                    end else begin
                        t_cnt_next = t_cnt_reg + 1;
                    end
                end
            end
            DATA_COMPARE: begin
                if (t_cnt_reg > 4) begin
                    data_next[39-data_cnt_reg] = 1;
                    if (data_cnt_reg < 39) begin
                        data_cnt_next = data_cnt_reg + 1;
                        t_cnt_next = 0;
                        n_state = DATA_SYNC;
                    end else if (data_cnt_reg == 39) begin
                        t_cnt_next = 0;
                        n_state = STOP;
                    end
                end else if (t_cnt_reg <= 4) begin
                    data_next[39-data_cnt_reg] = 0;
                    if (data_cnt_reg < 39) begin
                        data_cnt_next = data_cnt_reg + 1;
                        t_cnt_next = 0;
                        n_state = DATA_SYNC;
                    end else if (data_cnt_reg == 39) begin
                        t_cnt_next = 0;
                        n_state = STOP;
                    end
                end
            end

            STOP: begin
                if (total_sum == lsb) begin
                    valid_next = 1'b1;
                end else begin
                    valid_next = 1'b0;
                end

                if (w_tick) begin
                    if (t_cnt_reg == 4) begin
                        io_en_next = 1'b1;
                        t_cnt_next = t_cnt_reg + 1;
                        dht11_next = 1'b1;
                        data_cnt_next = 0;
                    end else if (t_cnt_reg == 400) begin
                        t_cnt_next = 0;
                        n_state = IDLE;
                    end else begin
                        t_cnt_next = t_cnt_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule





module tick_gen_10um (
    input  clk,
    input  rst,
    output o_tick
);
    parameter F_CNT = 1000;  //100KHz

    reg [$clog2(F_CNT)-1:0] counter_reg;
    reg o_tick_reg;

    assign o_tick = o_tick_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            o_tick_reg  <= 0;
        end else begin
            if (counter_reg == F_CNT - 1) begin
                counter_reg <= 0;
                o_tick_reg  <= 1'b1;
            end else begin
                counter_reg <= counter_reg + 1;
                o_tick_reg  <= 1'b0;
            end
        end
    end


endmodule
