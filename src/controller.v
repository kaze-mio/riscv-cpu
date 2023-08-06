`timescale 1ns / 1ps

`include "defines.vh"

module controller(
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire [6:0] funct7,
    
    output reg [1:0] npc_op,
    output reg rf_re1,
    output reg rf_re2,
    output reg rf_we,
    output reg [1:0] rf_wsel,
    output reg [2:0] sext_op,
    output reg alu_bsel,
    output reg [3:0] alu_op,
    output wire ram_we
);

    always @ (*) begin
        case (opcode)
            `OPCODE_B : npc_op = 2'd1;
            `OPCODE_JAL : npc_op = 2'd2;
            `OPCODE_JALR : npc_op = 2'd3;
            default : npc_op = 2'd0;
        endcase
    end

    always @ (*) begin
        case (opcode)
            `OPCODE_R : rf_re1 = 1'b1;
            `OPCODE_I : rf_re1 = 1'b1;
            `OPCODE_LW : rf_re1 = 1'b1;
            `OPCODE_JALR : rf_re1 = 1'b1;
            `OPCODE_SW : rf_re1 = 1'b1;
            `OPCODE_B : rf_re1 = 1'b1;
            default : rf_re1 = 1'b0;
        endcase
    end

    always @ (*) begin
        case (opcode)
            `OPCODE_R : rf_re2 = 1'b1;
            `OPCODE_SW : rf_re2 = 1'b1;
            `OPCODE_B : rf_re2 = 1'b1;
            default : rf_re2 = 1'b0;
        endcase
    end

    always @ (*) begin
        case (opcode)
            `OPCODE_R : rf_we = 1'b1;
            `OPCODE_I : rf_we = 1'b1;
            `OPCODE_LW : rf_we = 1'b1;
            `OPCODE_JALR : rf_we = 1'b1;
            `OPCODE_LUI : rf_we = 1'b1;
            `OPCODE_JAL : rf_we = 1'b1;
            default : rf_we = 1'b0;
        endcase
    end

    always @ (*) begin
        case (opcode)
            `OPCODE_LUI : rf_wsel = 2'd1;
            `OPCODE_LW : rf_wsel = 2'd2;
            `OPCODE_JAL : rf_wsel = 2'd3;
            `OPCODE_JALR : rf_wsel = 2'd3;
            default : rf_wsel = 2'd0;
        endcase
    end

    always @ (*) begin
        case (opcode)
            `OPCODE_I : sext_op = (funct3 == 3'b001 | funct3 == 3'b101) ? 3'd1 : 3'd0;
            `OPCODE_B : sext_op = 3'd2;
            `OPCODE_SW : sext_op = 3'd3;
            `OPCODE_LUI : sext_op = 3'd4;
            `OPCODE_JAL : sext_op = 3'd5;
            default : sext_op = 3'd0;
        endcase
    end

    always @ (*) begin
        case (opcode)
            `OPCODE_I : alu_bsel = 1'b1;
            `OPCODE_LW : alu_bsel = 1'b1;
            `OPCODE_JALR : alu_bsel = 1'b1;
            `OPCODE_SW : alu_bsel = 1'b1;
            default : alu_bsel = 1'b0;
        endcase
    end

    always @ (*) begin
        case (opcode)
            `OPCODE_R : begin
                case (funct3)
                    3'b000 : alu_op = funct7[5] ? 4'd1 : 4'd0; // add, sub
                    3'b111 : alu_op = 4'd2; // and
                    3'b110 : alu_op = 4'd3; // or
                    3'b100 : alu_op = 4'd4; // xor
                    3'b001 : alu_op = 4'd5; // sll
                    3'b101 : alu_op = funct7[5] ? 4'd7 : 4'd6; // srl, sra
                    default : alu_op = 4'd0;
                endcase
            end
            `OPCODE_I : begin
                case (funct3)
                    3'b000 : alu_op = 4'd0; // addi
                    3'b111 : alu_op = 4'd2; // andi
                    3'b110 : alu_op = 4'd3; // ori
                    3'b100 : alu_op = 4'd4; // xori
                    3'b001 : alu_op = 4'd5; // slli
                    3'b101 : alu_op = funct7[5] ? 4'd7 : 4'd6; // srli, srai
                    default : alu_op = 4'd0;
                endcase
            end
            `OPCODE_B : begin
                case (funct3)
                    3'b000 : alu_op = 4'd8; // beq
                    3'b001 : alu_op = 4'd9; // bne
                    3'b100 : alu_op = 4'd10; // blt
                    3'b101 : alu_op = 4'd11; // bge
                    default : alu_op = 4'd0;
                endcase
            end
            default : alu_op = 4'd0;
        endcase
    end

    assign ram_we = (opcode == `OPCODE_SW); // sw

endmodule
