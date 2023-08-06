`timescale 1ns / 1ps

module alu(
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [3:0] op,
    output reg [31:0] c,
    output reg f
);

    wire [4:0] b_t = b[4:0];

    always @ (*) begin
        case (op)
            4'd0 : c = a + b;
            4'd1 : c = a - b;
            4'd2 : c = a & b;
            4'd3 : c = a | b;
            4'd4 : c = a ^ b;
            4'd5 : c = a << b_t;
            4'd6 : c = a >> b_t;
            4'd7 : c = $signed(a) >>> b_t;
            default : c = 32'b0;
        endcase
    end

    always @ (*) begin
        case (op)
            4'd8 : f = a == b;
            4'd9 : f = a != b;
            4'd10 : f = $signed(a) < $signed(b);
            4'd11 : f = $signed(a) >= $signed(b);
            default : f = 1'b0;
        endcase
    end

endmodule
