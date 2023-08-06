`timescale 1ns / 1ps

module sext(
    input wire [2:0] op,
    input wire [24:0] din,
    output reg [31:0] ext
);

    wire sign = din[24];

    always @(*) begin
        case (op)
            3'd0 : ext = {sign ? 20'hFFFFF : 20'b0, din[24:13]}; // [31:20]
            3'd1 : ext = {27'b0, din[17:13]}; // [24:20]
            3'd2 : ext = {sign ? 19'h7FFFF : 19'b0, din[24], din[0], din[23:18], din[4:1], 1'b0}; // [31|7|30:25|11:8], beq
            3'd3 : ext = {sign ? 20'hFFFFF : 20'b0, din[24:18], din[4:0]}; // [31:25|11:7], sw
            3'd4 : ext = {din[24:5], 12'b0}; // [31:12], lui
            3'd5 : ext = {sign ? 11'h7FF : 11'b0, din[24], din[12:5], din[13], din[23:14], 1'b0}; // [31|19:12|20|30:21], jal
            default : ext = 32'b0;
        endcase
    end

endmodule