/*
The main stimulus class.

This class connects the opcode generator to the rest of the testbench. It will
also feed randomized data at some point.

TODO: Fill in other stimulus calls to OpcodeGenerator when available.
TODO: Randomize test data and opcodes, or call random function in OpcodeGenerator.
*/

import ibex_pkg::*;
class tester;

    virtual vip_bfm bfm;

    function new (virtual vip_bfm b);
        bfm = b;
    endfunction : new
    
    task execute();
        // Test addition with the default values - r1=5 r2=6 rd=7 val1=1 val2=2
        $display("===============Testing ADD with Defaults==================");
        bfm.init_mem(ALU_ADD);
        bfm.reset_cpu();
        repeat (50) begin
            @(negedge bfm.clk_sys);
        end
        // Test addition with the values r1=6 r2=7 rd=5 val1=2 val2=3
        $display("===============Testing ADD with 6-7-5 2-3=================");
        bfm.reset_cpu();
        bfm.setRegisters(6, 7, 5);
        bfm.setArithVals(2, 3);
        bfm.init_mem(ALU_ADD);
        bfm.reset_cpu();
        repeat (50) begin
            @(negedge bfm.clk_sys);
        end
        //STOP
        bfm.end_sim();
    endtask : execute

endclass : tester

