/*
The main coverage class.

This class will ensure coverage of a defined set of opcodes and check that the
FSMs are exercised.
*/
import ibex_pkg::*;

class coverage;

    virtual vip_bfm bfm;
    int arith1;
    int arith2;
    alu_op_e aluOp;
    md_op_e mdOp;

    covergroup op_cov;
        alu_ops: coverpoint aluOp {
            bins arith_cmds[] = {ALU_ADD, ALU_SUB, ALU_XOR, ALU_OR, ALU_AND,
                ALU_SRL, ALU_SLL};
            bins comp_cmds[] = {ALU_LT, ALU_LTU, ALU_GE, ALU_GEU, ALU_EQ,
                ALU_NE};
        }

        md_ops: coverpoint mdOp {
            bins mult_cmds[] = {MD_OP_MULL, MD_OP_MULH};
            bins div_cmds[] = {MD_OP_DIV, MD_OP_REM};
        }
    endgroup

    covergroup zeros_or_ones_on_ops;

        arith_1: coverpoint arith1 {
            bins zeros = {'h00000000};
            bins others = {['h00000001:'hFFFFFFFE]};
            bins ones = {'hFFFFFFFF};
        }

        arith_2: coverpoint arith2 {
            bins zeros = {'h00000000};
            bins others = {['h00000001:'hFFFFFFFE]};
            bins ones = {'hFFFFFFFF};
        }

        alu_op_00_FF:  cross arith_1, arith_2, aluOp {
            bins add_00 = binsof (aluOp) intersect {ALU_ADD} &&
                        (binsof (arith_1.zeros) || binsof (arith_2.zeros));

            bins add_FF = binsof (aluOp) intersect {ALU_ADD} &&
                        (binsof (arith_1.ones) || binsof (arith_2.ones));

            bins and_00 = binsof (aluOp) intersect {ALU_AND} &&
                        (binsof (arith_1.zeros) || binsof (arith_2.zeros));

            bins and_FF = binsof (aluOp) intersect {ALU_AND} &&
                        (binsof (arith_1.ones) || binsof (arith_2.ones));

            bins xor_00 = binsof (aluOp) intersect {ALU_XOR} &&
                        (binsof (arith_1.zeros) || binsof (arith_2.zeros));

            bins xor_FF = binsof (aluOp) intersect {ALU_XOR} &&
                        (binsof (arith_1.ones) || binsof (arith_2.ones));
        }

        md_op_00_FF:  cross arith_1, arith_2, mdOp {

            bins mul_00 = binsof (mdOp) intersect {MD_OP_MULL} &&
                        (binsof (arith_1.zeros) || binsof (arith_2.zeros));

            bins mul_FF = binsof (mdOp) intersect {MD_OP_MULL} &&
                        (binsof (arith_1.ones) || binsof (arith_2.ones));

            bins mul_max = binsof (mdOp) intersect {MD_OP_MULL} &&
                        (binsof (arith_1.ones) && binsof (arith_2.ones));

            ignore_bins others_only =
                                    binsof(arith_1.others) && binsof(arith_2.others);

        }
    endgroup

    function new (virtual vip_bfm b);
        op_cov = new();
        zeros_or_ones_on_ops = new();
        bfm = b;
    endfunction : new

    task execute();
        forever begin  : sampling_block
           @(negedge bfm.clk_sys);
           arith1 = bfm.test1;
           arith2 = bfm.test2;
           aluOp = bfm.currAluOp;
           //TODO: multOp
           //mdOp = bfm.currMdOp;
           op_cov.sample();
           zeros_or_ones_on_ops.sample();
        end : sampling_block
    endtask : execute
endclass : coverage

