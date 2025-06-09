`timescale 1ns / 1ps

module fnd_controller (
    input        clk,
    input        reset,
    input        sw_mode,
    input [15:0] cu_data,
    input        sw2, // blink
    input        sw1, // 0: msec/sec, 1: min/hour
    input    [23:0] data,
    input     [2:0] sel_sw,
    // input  [6:0] msec,
    // input  [5:0] sec,
    // input  [5:0] min,
    // input  [4:0] hour,
    output [7:0] fnd_data,
    output [3:0] fnd_com,
    output [15:0] uart_send_data
);
    wire [3:0] w_bcd, w_bcd_sr04, w_bcd_dht11;
    wire [3:0] w_msec1, w_mesc10, w_sec_1, w_sec_10;
    wire [3:0] w_min_1, w_min_10, w_hour_1, w_hour_10;
    wire [3:0] w_min_hour, w_msec_sec;
    wire w_oclk;
    wire [3:0] w_dot;
    wire [2:0] fnd_sel;
    wire w_blink_tick;
    wire [2:0] w_mux_8x1_sel; //
    wire sw1_sw2;
    wire sw12;
    wire [3:0] bcd;
    wire [15:0] w_sr04_fnd_data, w_dht11_fnd_data;


    assign sw1_sw2 = (~sw1) & sw2;
    ////////////////////////
    O_BCD_Watch U_O_BCD_WATCH(
        .time_data(data),
        .mux_8x1_sel(w_mux_8x1_sel),
        .i_dot(w_dot),
        .bcd_msec_sec(w_msec_sec),
        .bcd_min_hour(w_min_hour)
    );
    ////////////////
    O_BCD_sr04 U_sr04(
        .sr04_data(data),
        .fnd_sel(fnd_sel),
        .bcd(w_bcd_sr04),
        .sr04_fnd_data(w_sr04_fnd_data)
    );
    /////////////////////
    O_BCD_dht11 U_dht11(
        .dht11_data(data),
        .fnd_sel(fnd_sel),
        .bcd(w_bcd_dht11),
        . dht11_fnd_data(w_dht11_fnd_data)
    );
    ///////////////////////
    mux_2x1_blink U_blink_mux (
        .sw2(sw1_sw2),
        .fnd_sel(fnd_sel),
        .blink_tick(w_blink_tick),
        .o_blink_sel(w_mux_8x1_sel)
    );

    blink_gen U_blink (
        .clk(clk),
        .rst(reset),
        .blink_tick(w_blink_tick)
    );

    decoder_2x4 U_Decoder_2x4 (
        .fnd_sel(fnd_sel),
        .fnd_com(fnd_com)
    );

    mux2x1 U_MUX_2X1(
        .msec_sec(w_msec_sec),
        .min_hour(w_min_hour),
        .sel(sw_mode),
        .bcd(w_bcd)
    );
    MUX_3X1 U_MUX_3X1(
        .time_bcd(w_bcd),
        .sr04_bcd(w_bcd_sr04),
        .dht11_bcd(w_bcd_dht11),
        .sr04_data(w_sr04_fnd_data),
        .dht11_data(w_dht11_fnd_data),
        .sel_sw(sel_sw),
        .o_bcd(bcd),
        .uart_send_data(uart_send_data)   
    );

  

    comparator U_COMPAR(
    .i_msec(data[6:0]),
    .o_dot(w_dot)
    );

    bcd U_BCD (
        .bcd(bcd),
        .fnd_data(fnd_data)
    );

    counter_8 U_Counter8 (
        .clk(w_oclk),
        .reset(reset),
        .fnd_sel(fnd_sel)
    );

    clk_div U_clk_div (
        .clk  (clk),
        .reset(reset),
        .o_clk(w_oclk)
    );
endmodule
///////////////////////////////
module O_BCD_Watch (
    input [23:0]time_data,
    input [2:0]mux_8x1_sel,
    input [3:0] i_dot,
    output [3:0]bcd_msec_sec,
    output [3:0]bcd_min_hour
);
    wire [3:0] w_msec1, w_mesc10, w_sec_1, w_sec_10;
    wire [3:0] w_min_1, w_min_10, w_hour_1, w_hour_10;
    //ds msec
    digit_splitter #(
        .BIT_WIDTH(7)
    ) U_DS_MSEC (
        .time_data(time_data[6:0]),
        .digit_1  (w_msec1),
        .digit_10 (w_mesc10)
    );
    //ds sec
    digit_splitter #(
        .BIT_WIDTH(6)
    ) U_DS_SEC (
        .time_data(time_data[12:7]),
        .digit_1  (w_sec_1),
        .digit_10 (w_sec_10)
    );
    //ds min
    digit_splitter #(
        .BIT_WIDTH(6)
    ) U_DS_min (
        .time_data(time_data[18:13]),
        .digit_1  (w_min_1),
        .digit_10 (w_min_10)
    );
    //ds hour
    digit_splitter #(
        .BIT_WIDTH(5)
    ) U_DS_hour (
        .time_data(time_data[23:19]),
        .digit_1  (w_hour_1),
        .digit_10 (w_hour_10)
    );
    mux_8x1 U_MUX_8x1_msec_sec (
        .sel(mux_8x1_sel),
        .digit_1(w_msec1),
        .digit_10(w_mesc10),
        .digit_100 (w_sec_1),     // 입력 없으면 비워놓기, Error 발생 안함
        .digit_1000(w_sec_10),
        .i_dot(i_dot),
        .bcd(bcd_msec_sec)
    );
    mux_8x1 U_MUX_8x1_min_hour (
        .sel(mux_8x1_sel),
        .digit_1(w_min_1),
        .digit_10(w_min_10),
        .digit_100 (w_hour_1),     // 입력 없으면 비워놓기, Error 발생 안함
        .digit_1000(w_hour_10),
        .i_dot(i_dot),
        .bcd(bcd_min_hour)
    );
endmodule
///////////////////////////
module O_BCD_sr04 (
    input [23:0]sr04_data,
    input [2:0]fnd_sel,
    output [3:0]bcd,
    output [15:0] sr04_fnd_data
);
    wire [3:0] w_digit_0, w_digit_1, w_digit_10, w_digit_100;

    digit_splitter_sr04 U_Digit_SR04(
    .dist(sr04_data[13:4]),
    .dist_dot(sr04_data[3:0]),
    .digit_0(w_digit_0),
    .digit_1(w_digit_1),
    .digit_10(w_digit_10),
    .digit_100(w_digit_100),
    .sr04_fnd_data(sr04_fnd_data)
    );
    mux_8x1_sr04 U_MUX_8x1_sr04 (
        .sel(fnd_sel),
        .digit_0(w_digit_0),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .bcd(bcd)
    );


endmodule
/////////////////////////////////
module O_BCD_dht11 (
    input [23:0]dht11_data,
    input [2:0]fnd_sel,
    output [3:0]bcd,
    output [15:0] dht11_fnd_data
);
wire [3:0] w_digit_0, w_digit_1, w_digit_10, w_digit_100;
    digit_splitter_dht11 U_Digit_dht11(
    .t_data(dht11_data[7:0]),
    .rh_data(dht11_data[15:8]),
    .digit_1_t(w_digit_0),
    .digit_10_t(w_digit_1),
    .digit_1_rh(w_digit_10),
    .digit_10_rh(w_digit_100),
    .dht11_data(dht11_fnd_data)
    );
    mux_8x1_dht11 U_MUX_8x1_dht11 (
        .sel(fnd_sel),
        .digit_1_t(w_digit_0),
        .digit_10_t(w_digit_1),
        .digit_1_rh(w_digit_10),
        .digit_10_rh(w_digit_100),
        .bcd(bcd)
    );

endmodule
////////////////////////////////

module digit_splitter_dht11 (
    input  [7:0] rh_data,
    input  [7:0] t_data,
    output [ 3:0] digit_1_t,
    output [ 3:0] digit_10_t,
    output [ 3:0] digit_1_rh,
    output [ 3:0] digit_10_rh,
    output [15:0] dht11_data
);

    assign dht11_data = {digit_10_rh,digit_1_rh,digit_10_t,digit_1_t};
    assign digit_1_t = t_data % 10;
    assign digit_10_t = (t_data / 10) % 10;
    assign digit_1_rh = rh_data % 10;
    assign digit_10_rh = (rh_data / 10) %10;

endmodule

module mux_8x1_dht11 (
    input  [2:0] sel,
    input  [3:0] digit_1_t,
    input  [3:0] digit_10_t,
    input  [3:0] digit_1_rh,
    input  [3:0] digit_10_rh,
    output [3:0] bcd
);

    reg [3:0] r_bcd;
    assign bcd = r_bcd;

    always @(*) begin
        case (sel)
            3'b000: r_bcd = digit_1_t;
            3'b001: r_bcd = digit_10_t;
            3'b010: r_bcd = digit_1_rh;
            3'b011: r_bcd = digit_10_rh;
            3'b100: r_bcd = digit_1_t;
            3'b101: r_bcd = digit_10_t;
            3'b110: r_bcd = 4'h0e;
            3'b111: r_bcd = digit_10_rh;
        endcase
    end
endmodule

module digit_splitter_sr04 (
    input  [9:0] dist,
    input  [3:0] dist_dot,
    output [ 3:0] digit_0,
    output [ 3:0] digit_1,
    output [ 3:0] digit_10,
    output [ 3:0] digit_100,
    output [15:0] sr04_fnd_data
);

    assign sr04_fnd_data = {digit_100,digit_10,digit_1,digit_0};

    assign digit_0 = dist_dot % 10;
    assign digit_1 = dist % 10;
    assign digit_10 = (dist / 10) % 10;
    assign digit_100 = (dist / 100) % 10;
endmodule

module mux_8x1_sr04 (
    input  [2:0] sel,
    input  [3:0] digit_0,
    input  [3:0] digit_1,
    input  [3:0] digit_10,
    input  [3:0] digit_100,
    output [3:0] bcd
);

    reg [3:0] r_bcd;
    assign bcd = r_bcd;

    always @(*) begin
        case (sel)
            3'b000: r_bcd = digit_0;
            3'b001: r_bcd = digit_1;
            3'b010: r_bcd = digit_10;
            3'b011: r_bcd = digit_100;
            3'b100: r_bcd = digit_0;
            3'b101: r_bcd = 4'h0e;
            3'b110: r_bcd = digit_10;
            3'b111: r_bcd = digit_100;
        endcase
    end
endmodule
/*
module demux3x1(
    input [23:0] data,
    input [2:0] sel_sw,
    output reg [23:0] time_data,
    output reg [23:0] sr04,
    output reg [23:0] dht11
);

    always @(*) begin
        time_data = 0;
        sr04 = 0;
        dht11 = 0;
        case (sel_sw)
           3'b001 : time_data = data;
           3'b010 : sr04 = data;
           3'b100 : dht11 = data;
            default: begin
                time_data = 0;
                sr04 = 0;
                dht11 = 0;
            end
        endcase
    end
endmodule
*/
module MUX_3X1 (
    input [3:0] time_bcd,
    input [3:0] sr04_bcd,
    input [3:0] dht11_bcd,
    input [15:0] sr04_data,
    input [15:0] dht11_data,
    input [2:0] sel_sw,
    output reg [3:0] o_bcd,
    output reg [15:0] uart_send_data
);




always @(*) begin
    o_bcd = 0;
    uart_send_data = 0;
    case (sel_sw)
        3'b001: begin
            o_bcd = time_bcd;
            uart_send_data = 0;
        end
        3'b010: begin
            o_bcd = sr04_bcd;
            uart_send_data = sr04_data;
        end
       
        3'b100: begin
            o_bcd = dht11_bcd;
            uart_send_data = dht11_data;
        end
    endcase
end
    
endmodule

//mux 2x1 msec_sec, min_hour
module mux2x1 (
    input  [3:0] msec_sec,
    input  [3:0] min_hour,
    input        sel,
    output [3:0] bcd
);
    assign bcd = (sel) ? min_hour : msec_sec;
endmodule



module clk_div (
    input  clk,
    input  reset,
    output o_clk
);
    //clk 100_000_000, r_count = 100_000
    //reg [16:0] r_counter;
    reg [$clog2(100_000)-1:0] r_counter;
    reg r_clk;

    assign o_clk = r_clk;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
            r_clk     <= 1'b0;
        end else begin
            if (r_counter == 100_000 - 1) begin  //1khz period
                r_counter <= 0;
                r_clk <= 1'b1;
            end else begin
                r_counter <= r_counter + 1;
                r_clk <= 1'b0;
            end
        end
    end
endmodule


//팔진카운터
module counter_8 (
    input        clk,
    input        reset,
    output [2:0] fnd_sel
);
    reg [2:0] r_counter;
    assign fnd_sel = r_counter;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
        end else begin
            r_counter <= r_counter + 1;
        end
    end

endmodule
//DS
module digit_splitter #(
    parameter BIT_WIDTH = 7
) (
    input  [BIT_WIDTH-1:0] time_data,
    output [          3:0] digit_1,
    output [          3:0] digit_10

);
    assign digit_1  = time_data % 10;
    assign digit_10 = (time_data / 10) % 10;
endmodule

//2x4 디코더
module decoder_2x4 (
    input      [2:0] fnd_sel,
    output reg [3:0] fnd_com
);

    always @(fnd_sel) begin
        case (fnd_sel[1:0]) //하위 2비트만 비교교
            2'b00:   fnd_com = 4'b1110;
            2'b01:   fnd_com = 4'b1101;
            2'b10:   fnd_com = 4'b1011;
            2'b11:   fnd_com = 4'b0111;
            default: fnd_com = 4'b1111;
        endcase
    end

endmodule
//비교기
module comparator (
    input  [6:0] i_msec,
    output reg [3:0] o_dot
);
    //assign o_dot = (i_msec > 49) ? 4'h0e : 4'h0f;
    always @(*) begin
        if (i_msec<50) begin
            o_dot=4'h0f;
        end else begin
            o_dot=4'h0e;
        end
    end
    
endmodule

module mux_8x1 (
    input  [3:0] digit_1,
    input  [3:0] digit_10,
    input  [3:0] digit_100,
    input  [3:0] digit_1000,
    input  [3:0] i_dot,
    input  [2:0] sel,
    output [3:0] bcd
);
    reg [3:0] r_bcd;
    assign bcd = r_bcd;
    //letch줄이는법  초기값이나 디폴트 설정을 잘한다
    // 4:1 mux , always
    always @(*) begin
        case (sel)
            3'b000: r_bcd = digit_1;
            3'b001: r_bcd = digit_10;
            3'b010: r_bcd = digit_100;
            3'b011: r_bcd = digit_1000;
            3'b110: r_bcd = i_dot;
            default: r_bcd = 4'h0f;
        endcase 
    end

endmodule

module bcd (
    input  [3:0] bcd,
    output [7:0] fnd_data
);

    reg [7:0] r_fnd_data;
    assign fnd_data = r_fnd_data;
    //조합논리 : assign
    //조합논리 combinatioal , 행위수준 모델링 always 출력 보낼때 reg 타입
    always @(bcd) begin
        case (bcd)
            4'h00:   r_fnd_data = 8'hc0;
            4'h01:   r_fnd_data = 8'hf9;
            4'h02:   r_fnd_data = 8'ha4;
            4'h03:   r_fnd_data = 8'hb0;
            4'h04:   r_fnd_data = 8'h99;
            4'h05:   r_fnd_data = 8'h92;
            4'h06:   r_fnd_data = 8'h82;
            4'h07:   r_fnd_data = 8'hf8;
            4'h08:   r_fnd_data = 8'h80;
            4'h09:   r_fnd_data = 8'h90;
            4'h0a:   r_fnd_data = 8'hff;
            4'h0e:   r_fnd_data = 8'h7f; //dot on
            4'h0f:   r_fnd_data = 8'hff; //dot off
            default: r_fnd_data = 8'hff;
        endcase
    end

endmodule


module blink_gen (
    input clk,
    input rst,
    output reg blink_tick
);

    parameter COUNT = 20000000;
    reg [24:0] r_count;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_count <= 0;
            blink_tick <= 0;
        end else if (r_count == COUNT - 1) begin
            r_count <= 0;
        end else if (r_count < (COUNT / 2)) begin
            r_count <= r_count + 1;
            blink_tick <= 1'b1;
        end else begin
            r_count <= r_count + 1;
            blink_tick <= 1'b0;
        end
    end

endmodule

module mux_2x1_blink (
    input sw2,
    input [2:0] fnd_sel,
    input blink_tick,
    output [2:0] o_blink_sel
);
    assign o_blink_sel = sw2 ? {blink_tick, fnd_sel[1:0]} : fnd_sel;

endmodule

