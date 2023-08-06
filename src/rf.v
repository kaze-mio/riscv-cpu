`timescale 1ns / 1ps

module rf(
    input wire clk,
    input wire rst,
    input wire [4:0] raddr1,
    input wire [4:0] raddr2,
    input wire [4:0] waddr,
    input wire wen,
    input wire [31:0] wdata,
    output wire [31:0] rdata1,
    output wire [31:0] rdata2
);

    reg [31:0] reg_array [31:0];

    always @ (posedge clk or posedge rst) begin
        if (rst)
            for (integer i = 0; i < 32; i = i + 1) begin
                reg_array[i] <= 32'b0;
            end
        else if (wen & waddr != 5'b0)
            reg_array[waddr] <= wdata;
    end

    assign rdata1 = (raddr1 != 5'b0) ? reg_array[raddr1] : 32'b0;

    assign rdata2 = (raddr2 != 5'b0) ? reg_array[raddr2] : 32'b0;

endmodule
