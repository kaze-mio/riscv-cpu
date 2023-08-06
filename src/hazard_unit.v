`timescale 1ns / 1ps

module hazard_unit (
    input wire [1:0] npc_op_id,
    input wire re1_id,
    input wire re2_id,
    input wire [4:0] raddr1_id,
    input wire [4:0] raddr2_id,

    input wire [1:0] npc_op_ex,
    input wire we_ex,
    input wire [1:0] wsel_ex,
    input wire [4:0] waddr_ex,
    input wire [31:0] wdata_ex,

    input wire we_mem,
    input wire [4:0] waddr_mem,
    input wire [31:0] wdata_mem,

    input wire we_wb,
    input wire [4:0] waddr_wb,
    input wire [31:0] wdata_wb,

    output wire pc_stall,
    output wire if_id_stall,
    output wire if_id_flush,
    output wire id_ex_stall,
    output wire id_ex_flush,

    output wire rdata1_sel,
    output wire rdata2_sel,
    output reg [31:0] rdata1_fwd,
    output reg [31:0] rdata2_fwd
);

    /*
        [Data Hazard (Without Forwarding)]
        InstA: PC (Write Reg)
        InstB: PC+4 (Read Reg)
        | PC            | IF->ID REG    | ID->EX REG    | EX->MEM REG    | MEM->WB REG    |
        | InstC         | InstB         | InstA         |                |                |
        | InstC(Stall)  | InstB(Stall)  | Bubble(Flush) | InstA          |                |
        | InstC(Stall)  | InstB(Stall)  | Bubble(Flush) | Bubble         | InstA          |
        | InstC(Stall)  | InstB(Stall)  | Bubble(Flush) | Bubble         | Bubble         |
        | InstD         | InstC         | InstB         | Bubble         | Bubble         |

        [Control Hazard (jal)]
        InstA: PC (jal)
        InstB: PC+4
        InstB': PC+offset
        | PC            | IF->ID REG    | ID->EX REG    | EX->MEM REG    | MEM->WB REG    |
        | InstB         | InstA         |               |                |                |
        | InstB'        | Bubble(Flush) | InstA         |                |                |
        | InstC'        | InstB'        | Bubble        | InstA          |                |

        [Control Hazard (B, jalr)]
        | PC            | IF->ID REG    | ID->EX REG    | EX->MEM REG    | MEM->WB REG    |
        | InstC         | InstB         | InstA         |                |                |
        | InstB'        | Bubble(Flush) | Bubble(Flush) | InstA          |                |
        | InstC'        | InstB'        | Bubble        | Bubble         | InstA          |
    */

    // Detect

    wire data1_ex = re1_id & we_ex & (raddr1_id == waddr_ex) & (raddr1_id != 5'b0);
    wire data1_mem = re1_id & we_mem & (raddr1_id == waddr_mem)  & (raddr1_id != 5'b0);
    wire data1_wb = re1_id & we_wb & (raddr1_id == waddr_wb)  & (raddr1_id != 5'b0);

    wire data2_ex = re2_id & we_ex & (raddr2_id == waddr_ex) & (raddr2_id != 5'b0);
    wire data2_mem = re2_id & we_mem & (raddr2_id == waddr_mem)  & (raddr2_id != 5'b0);
    wire data2_wb = re2_id & we_wb & (raddr2_id == waddr_wb)  & (raddr2_id != 5'b0);

    wire load_use = (data1_ex | data2_ex) & (wsel_ex == 2'd2);

    wire control_id = (npc_op_id == 2'd2);
    wire control_ex = (npc_op_ex == 2'd1) | (npc_op_ex == 2'd3);
    wire control = control_id | control_ex;

    // Forward

    assign rdata1_sel = ~control & (data1_ex | data1_mem | data1_wb);
    assign rdata2_sel = ~control & (data2_ex | data2_mem | data2_wb);

    always @ (*) begin
        if (data1_ex)
            rdata1_fwd = wdata_ex;
        else if (data1_mem)
            rdata1_fwd = wdata_mem;
        else if (data1_wb)
            rdata1_fwd = wdata_wb;
        else
            rdata1_fwd = 32'b0;
    end

    always @ (*) begin
        if (data2_ex)
            rdata2_fwd = wdata_ex;
        else if (data2_mem)
            rdata2_fwd = wdata_mem;
        else if (data2_wb)
            rdata2_fwd = wdata_wb;
        else
            rdata2_fwd = 32'b0;
    end

    // Stall & Flush

    wire load_use_t = ~control & load_use;
    assign pc_stall = load_use_t;
    assign if_id_stall = load_use_t;
    assign if_id_flush = control_id | control_ex;
    assign id_ex_stall = 1'b0;
    assign id_ex_flush = load_use_t | control_ex;

endmodule
