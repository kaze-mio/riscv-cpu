`timescale 1ns / 1ps

module id_ex_reg (
    input wire clk,
    input wire rst,
    input wire stall,
    input wire flush,

    input wire [1:0] npc_op_d,
    input wire rf_we_d,
    input wire [1:0] rf_wsel_d,
    input wire alu_bsel_d,
    input wire [3:0] alu_op_d,
    input wire ram_we_d,
    input wire [31:0] pc_d,
    input wire [31:0] pc4_d,
    input wire [31:0] rf_rdata1_d,
    input wire [31:0] rf_rdata2_d,
    input wire [4:0] rf_waddr_d,
    input wire [31:0] sext_ext_d,

    output reg [1:0] npc_op_q,
    output reg rf_we_q,
    output reg [1:0] rf_wsel_q,
    output reg alu_bsel_q,
    output reg [3:0] alu_op_q,
    output reg ram_we_q,
    output reg [31:0] pc_q,
    output reg [31:0] pc4_q,
    output reg [31:0] rf_rdata1_q,
    output reg [31:0] rf_rdata2_q,
    output reg [4:0] rf_waddr_q,
    output reg [31:0] sext_ext_q
);

    always @ (posedge clk or posedge rst) begin
        if (rst | flush) begin
            npc_op_q <= 2'b0;
            rf_we_q <= 1'b0;
            rf_wsel_q <= 2'b0;
            alu_bsel_q <= 1'b0;
            alu_op_q <= 4'b0;
            ram_we_q <= 1'b0;
            pc_q <= 32'b0;
            pc4_q <= 32'b0;
            rf_rdata1_q <= 32'b0;
            rf_rdata2_q <= 32'b0;
            rf_waddr_q <= 5'b0;
            sext_ext_q <= 32'b0;
        end else if (~stall) begin
            npc_op_q <= npc_op_d;
            rf_we_q <= rf_we_d;
            rf_wsel_q <= rf_wsel_d;
            alu_bsel_q <= alu_bsel_d;
            alu_op_q <= alu_op_d;
            ram_we_q <= ram_we_d;
            pc_q <= pc_d;
            pc4_q <= pc4_d;
            rf_rdata1_q <= rf_rdata1_d;
            rf_rdata2_q <= rf_rdata2_d;
            rf_waddr_q <= rf_waddr_d;
            sext_ext_q <= sext_ext_d;
        end
    end

endmodule
