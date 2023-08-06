`timescale 1ns / 1ps

module ex_mem_reg (
    input wire clk,
    input wire rst,
    
    input wire rf_we_d,
    input wire [1:0] rf_wsel_d,
    input wire ram_we_d,
    input wire [31:0] rf_rdata2_d,
    input wire [4:0] rf_waddr_d,
    input wire [31:0] rf_wdata_d,
    input wire [31:0] alu_c_d,

    output reg rf_we_q,
    output reg [1:0] rf_wsel_q,
    output reg ram_we_q,
    output reg [31:0] rf_rdata2_q,
    output reg [4:0] rf_waddr_q,
    output reg [31:0] rf_wdata_q,
    output reg [31:0] alu_c_q
);

    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            rf_we_q <= 1'b0;
            rf_wsel_q <= 2'b0;
            ram_we_q <= 1'b0;
            rf_rdata2_q <= 32'b0;
            rf_waddr_q <= 5'b0;
            rf_wdata_q <= 32'b0;
            alu_c_q <= 32'b0;
        end else begin
            rf_we_q <= rf_we_d;
            rf_wsel_q <= rf_wsel_d;
            ram_we_q <= ram_we_d;
            rf_rdata2_q <= rf_rdata2_d;
            rf_waddr_q <= rf_waddr_d;
            rf_wdata_q <= rf_wdata_d;
            alu_c_q <= alu_c_d;
        end
    end

endmodule
