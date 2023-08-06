`timescale 1ns / 1ps

module mem_wb_reg (
    input wire clk,
    input wire rst,
    
    input wire rf_we_d,
    input wire [4:0] rf_waddr_d,
    input wire [31:0] rf_wdata_d,

    output reg rf_we_q,
    output reg [4:0] rf_waddr_q,
    output reg [31:0] rf_wdata_q
);

    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            rf_we_q <= 1'b0;
            rf_waddr_q <= 5'b0;
            rf_wdata_q <= 32'b0;
        end else begin
            rf_we_q <= rf_we_d;
            rf_waddr_q <= rf_waddr_d;
            rf_wdata_q <= rf_wdata_d;
        end
    end

endmodule