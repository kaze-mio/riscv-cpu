`timescale 1ns / 1ps

`include "defines.vh"

module cpu (
    input  wire         cpu_rst,
    input  wire         cpu_clk,

    // Interface to IROM
    output wire [13:0]  inst_addr,
    input  wire [31:0]  inst,
    
    // Interface to Bridge
    output wire [31:0]  Bus_addr,
    input  wire [31:0]  Bus_rdata,
    output wire         Bus_wen,
    output wire [31:0]  Bus_wdata
);

    // Hazard Unit

    wire pc_stall;
    wire if_id_stall;
    wire if_id_flush;
    wire id_ex_stall;
    wire id_ex_flush;

    // -> IF

    /*
        [NPC Logic]
        0. npc_op = npc_op_id; npc_if = pc4_if
        1. npc_op = npc_op_ex; npc_if = alu_f_ex ? (pc_ex + sext_ext_ex) : pc4_ex (B)
        2. npc_op = npc_op_id; npc_if = pc_id + sext_ext_id (jal)
        3. npc_op = npc_op_ex; npc_if = alu_c_ex (jalr)
    */

    wire [31:0] pc_if;
    wire [31:0] pc4_if;
    reg [31:0] npc_if;

    assign pc4_if = pc_if + 32'h4;

    wire [1:0] npc_op = ((npc_op_ex == 2'd1) | (npc_op_ex == 2'd3)) ? npc_op_ex : npc_op_id;

    always @ (*) begin
        case (npc_op)
            2'd0 : npc_if = pc4_if;
            2'd1 : npc_if = alu_f_ex ? (pc_ex + sext_ext_ex) : pc4_ex;
            2'd2 : npc_if = pc_id + sext_ext_id;
            2'd3 : npc_if = alu_c_ex;
            default : npc_if = 32'b0;
        endcase
    end

    pc u_pc(
        .clk(cpu_clk),
        .rst(cpu_rst),
        .stall(pc_stall),
        .din(npc_if),
        .pc(pc_if)
    );

    assign inst_addr = pc_if[15:2];

    // IF -> ID

    wire [31:0] pc_id;
    wire [31:0] pc4_id;
    wire [31:0] inst_id;

    if_id_reg u_if_id_reg(
        .clk(cpu_clk),
        .rst(cpu_rst),
        .stall(if_id_stall),
        .flush(if_id_flush),

        .pc_d(pc_if),
        .pc4_d(pc4_if),
        .inst_d(inst),

        .pc_q(pc_id),
        .pc4_q(pc4_id),
        .inst_q(inst_id)
    );

    wire [6:0] opcode_id = inst_id[6:0];

    wire [1:0] npc_op_id;
    wire rf_re1_id;
    wire rf_re2_id;
    wire rf_we_id;
    wire [1:0] rf_wsel_id;
    wire [2:0] sext_op_id;
    wire alu_bsel_id;
    wire [3:0] alu_op_id;
    wire ram_we_id;

    wire [31:0] sext_ext_id;
    wire [31:0] rf_rdata1_id;
    wire [31:0] rf_rdata2_id;
    wire [4:0] rf_raddr1_id = inst_id[19:15];
    wire [4:0] rf_raddr2_id = inst_id[24:20];

    wire rf_we_wb;
    wire [4:0] rf_waddr_wb;
    wire [31:0] rf_wdata_wb;

    controller u_controller(
        .opcode(opcode_id),
        .funct3(inst_id[14:12]),
        .funct7(inst_id[31:25]),

        .npc_op(npc_op_id),
        .rf_re1(rf_re1_id),
        .rf_re2(rf_re2_id),
        .rf_we(rf_we_id),
        .rf_wsel(rf_wsel_id),
        .sext_op(sext_op_id),
        .alu_bsel(alu_bsel_id),
        .alu_op(alu_op_id),
        .ram_we(ram_we_id)
    );

    rf u_rf(
        .clk(cpu_clk),
        .rst(cpu_rst),

        .raddr1(rf_raddr1_id),
        .raddr2(rf_raddr2_id),
        .waddr(rf_waddr_wb),
        .wen(rf_we_wb),
        .wdata(rf_wdata_wb),

        .rdata1(rf_rdata1_id),
        .rdata2(rf_rdata2_id)
    );

    sext u_sext(
        .op(sext_op_id),
        .din(inst_id[31:7]),
        .ext(sext_ext_id)
    );

    // ID -> EX

    wire rf_rdata1_sel;
    wire rf_rdata2_sel;
    wire [31:0] rf_rdata1_fwd;
    wire [31:0] rf_rdata2_fwd;

    wire [1:0] npc_op_ex;
    wire rf_we_ex;
    wire [1:0] rf_wsel_ex;
    wire alu_bsel_ex;
    wire [3:0] alu_op_ex;
    wire ram_we_ex;

    wire [31:0] pc_ex;
    wire [31:0] pc4_ex;
    wire [31:0] rf_rdata1_ex;
    wire [31:0] rf_rdata2_ex;
    wire [4:0] rf_waddr_ex;
    wire [31:0] sext_ext_ex;

    id_ex_reg u_id_ex_reg(
        .clk(cpu_clk),
        .rst(cpu_rst),
        .stall(id_ex_stall),
        .flush(id_ex_flush),

        .npc_op_d(npc_op_id),
        .rf_we_d(rf_we_id),
        .rf_wsel_d(rf_wsel_id),
        .alu_bsel_d(alu_bsel_id),
        .alu_op_d(alu_op_id),
        .ram_we_d(ram_we_id),
        .pc_d(pc_id),
        .pc4_d(pc4_id),
        .rf_rdata1_d(rf_rdata1_sel ? rf_rdata1_fwd : rf_rdata1_id),
        .rf_rdata2_d(rf_rdata2_sel ? rf_rdata2_fwd : rf_rdata2_id),
        .rf_waddr_d(inst_id[11:7]),
        .sext_ext_d(sext_ext_id),

        .npc_op_q(npc_op_ex),
        .rf_we_q(rf_we_ex),
        .rf_wsel_q(rf_wsel_ex),
        .alu_bsel_q(alu_bsel_ex),
        .alu_op_q(alu_op_ex),
        .ram_we_q(ram_we_ex),
        .pc_q(pc_ex),
        .pc4_q(pc4_ex),
        .rf_rdata1_q(rf_rdata1_ex),
        .rf_rdata2_q(rf_rdata2_ex),
        .rf_waddr_q(rf_waddr_ex),
        .sext_ext_q(sext_ext_ex)
    );

    wire [31:0] alu_a_ex = rf_rdata1_ex;
    wire [31:0] alu_b_ex = alu_bsel_ex ? sext_ext_ex : rf_rdata2_ex;
    wire [31:0] alu_c_ex;
    wire alu_f_ex;
    reg [31:0] rf_wdata_ex;

    alu u_alu(
        .a(alu_a_ex),
        .b(alu_b_ex),
        .op(alu_op_ex),
        .c(alu_c_ex),
        .f(alu_f_ex)
    );

    always @ (*) begin
        case (rf_wsel_ex)
            2'd0 : rf_wdata_ex = alu_c_ex;
            2'd1 : rf_wdata_ex = sext_ext_ex;
            2'd3 : rf_wdata_ex = pc4_ex;
            default : rf_wdata_ex = 32'b0;
        endcase
    end

    // EX -> MEM

    wire rf_we_mem;
    wire [1:0] rf_wsel_mem;
    wire ram_we_mem;
    wire [31:0] rf_rdata2_mem;
    wire [4:0] rf_waddr_mem;
    wire [31:0] rf_wdata_raw_mem;
    wire [31:0] alu_c_mem;

    ex_mem_reg u_ex_mem_reg(
        .clk(cpu_clk),
        .rst(cpu_rst),

        .rf_we_d(rf_we_ex),
        .rf_wsel_d(rf_wsel_ex),
        .ram_we_d(ram_we_ex),
        .rf_rdata2_d(rf_rdata2_ex),
        .rf_waddr_d(rf_waddr_ex),
        .rf_wdata_d(rf_wdata_ex),
        .alu_c_d(alu_c_ex),

        .rf_we_q(rf_we_mem),
        .rf_wsel_q(rf_wsel_mem),
        .ram_we_q(ram_we_mem),
        .rf_rdata2_q(rf_rdata2_mem),
        .rf_waddr_q(rf_waddr_mem),
        .rf_wdata_q(rf_wdata_raw_mem),
        .alu_c_q(alu_c_mem)
    );

    assign Bus_addr = alu_c_mem;
    assign Bus_wen = ram_we_mem;
    assign Bus_wdata = rf_rdata2_mem;

    reg [31:0] rf_wdata_mem;

    always @ (*) begin
        case (rf_wsel_mem)
            2'd2 : rf_wdata_mem = Bus_rdata;
            default : rf_wdata_mem = rf_wdata_raw_mem;
        endcase
    end

    // MEM -> WB

    mem_wb_reg u_mem_wb_reg(
        .clk(cpu_clk),
        .rst(cpu_rst),

        .rf_we_d(rf_we_mem),
        .rf_waddr_d(rf_waddr_mem),
        .rf_wdata_d(rf_wdata_mem),

        .rf_we_q(rf_we_wb),
        .rf_waddr_q(rf_waddr_wb),
        .rf_wdata_q(rf_wdata_wb)
    );

    // Hazard Unit

    hazard_unit u_hazard_unit(
        .npc_op_id(npc_op_id),
        .re1_id(rf_re1_id),
        .re2_id(rf_re2_id),
        .raddr1_id(rf_raddr1_id),
        .raddr2_id(rf_raddr2_id),

        .npc_op_ex(npc_op_ex),
        .we_ex(rf_we_ex),
        .wsel_ex(rf_wsel_ex),
        .waddr_ex(rf_waddr_ex),
        .wdata_ex(rf_wdata_ex),

        .we_mem(rf_we_mem),
        .waddr_mem(rf_waddr_mem),
        .wdata_mem(rf_wdata_mem),

        .we_wb(rf_we_wb),
        .waddr_wb(rf_waddr_wb),
        .wdata_wb(rf_wdata_wb),

        .pc_stall(pc_stall),
        .if_id_stall(if_id_stall),
        .if_id_flush(if_id_flush),
        .id_ex_stall(id_ex_stall),
        .id_ex_flush(id_ex_flush),

        .rdata1_sel(rf_rdata1_sel),
        .rdata2_sel(rf_rdata2_sel),
        .rdata1_fwd(rf_rdata1_fwd),
        .rdata2_fwd(rf_rdata2_fwd)
    );

endmodule
