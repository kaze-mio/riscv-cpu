`timescale 1ns / 1ps

module if_id_reg (
    input wire clk,
    input wire rst,
    input wire stall,
    input wire flush,

    input wire [31:0] pc_d,
    input wire [31:0] pc4_d,
    input wire [31:0] inst_d,

    output reg [31:0] pc_q,
    output reg [31:0] pc4_q,
    output reg [31:0] inst_q
);

    always @ (posedge clk or posedge rst) begin
        if (rst | flush) begin
            pc_q <= 32'b0;
            pc4_q <= 32'b0;
            inst_q <= 32'b0;
        end else if (~stall) begin
            pc_q <= pc_d;
            pc4_q <= pc4_d;
            inst_q <= inst_d;
        end
    end

endmodule
