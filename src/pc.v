`timescale 1ns / 1ps

module pc(
    input wire clk,
    input wire rst,
    input wire stall,
    input wire [31:0] din,
    output reg [31:0] pc
);

    always @ (posedge clk or posedge rst) begin
        if (rst)
            pc <= 32'b0;
        else if (~stall)
            pc <= din;
        else
            pc <= pc;
    end

endmodule
