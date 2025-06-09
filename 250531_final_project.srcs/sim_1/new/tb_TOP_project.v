`timescale 1ns / 1ps

module tb_TOP_project;

    reg clk;
    reg rst;
    reg echo;
    reg [5:0] sw;
    reg btnL, btnR, btnU, btnD;
    reg rx;
    wire tx;
    wire trig;
    wire [7:0] fnd_data;
    wire [3:0] fnd_com;
    wire dht11_io;

    // 인스턴스화
    TOP_project dut (
        .clk(clk),
        .rst(rst),
        .echo(echo),
        .sw(sw),
        .btnL(btnL),
        .btnR(btnR),
        .btnU(btnU),
        .btnD(btnD),
        .rx(rx),
        .tx(tx),
        .trig(trig),
        .fnd_data(fnd_data),
        .fnd_com(fnd_com),
        .dht11_io(dht11_io)
    );

    // Clock 생성: 100MHz
    always #5 clk = ~clk;  

   // UART RX 신호 생성 task (8N1, LSB first, uart_rx 오버샘플링 구조에 맞춤)
task uart_send_byte;
    input [7:0] data;
    integer i;
    begin
        rx = 1; #(10417); // Idle 유지
        rx = 0; #(10417); // Start bit (1비트 시간)
        for (i = 0; i < 8; i = i + 1) begin
            rx = data[i]; #(10417); // LSB부터 1비트씩
        end
        rx = 1; #(10417); // Stop bit
    end
endtask

    initial begin

        // 초기화
        clk = 0;
        rst = 1;
        echo = 0;
        sw = 6'b000000;
        btnL = 0;
        btnR = 0;
        btnU = 0;
        btnD = 0;
        rx = 1; // Idle 상태 (UART high)

        // 리셋 해제
        #100;
        rst = 0;

        // UART로 'H'(0x48) 전송 (DHT11_START)
        #100;
        uart_send_byte(8'h37);
        #1000000;
        $finish;
    end

endmodule
