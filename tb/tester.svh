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
        
        //RANDO
        bfm.reset_cpu();
        bfm.init_mem();
        bfm.reset_cpu();
        repeat (50) begin
            @(negedge bfm.clk_sys);
        end
/*
        // Test subtraction with the values r1=7 r2=6 rd=5 val1=10 val2=4
        $display("===============Testing SUB with 7-6-5 10-4=================");
        bfm.reset_cpu();
        bfm.setRegisters(7, 6, 5);
        bfm.setArithVals(10, 4);
        bfm.init_mem(ALU_SUB);
        bfm.reset_cpu();
        repeat (50) begin
            @(negedge bfm.clk_sys);
        end

        $display("===============Testing XOR with 7-6-5 170-255=================");
        bfm.reset_cpu();
        bfm.setRegisters(7, 6, 5);
        bfm.setArithVals(170, 255);
        bfm.init_mem(ALU_XOR);
        bfm.reset_cpu();
        repeat (50) begin
            @(negedge bfm.clk_sys);
        end

        $display("===============Testing OR with 7-6-5 170-255=================");
        bfm.reset_cpu();
        bfm.setRegisters(7, 6, 5);
        bfm.setArithVals(170, 255);
        bfm.init_mem(ALU_OR);
        bfm.reset_cpu();
        repeat (50) begin
            @(negedge bfm.clk_sys);
        end

        $display("===============Testing AND with 7-6-5 170-255=================");
        bfm.reset_cpu();
        bfm.setRegisters(7, 6, 5);
        bfm.setArithVals(170, 255);
        bfm.init_mem(ALU_AND);
        bfm.reset_cpu();
        repeat (50) begin
            @(negedge bfm.clk_sys);
        end

        $display("===============Testing SRL with 7-6-5 170-3=================");
        bfm.reset_cpu();
        bfm.setRegisters(7, 6, 5);
        bfm.setArithVals(170,3);
        bfm.init_mem(ALU_SRL);
        bfm.reset_cpu();
        repeat (50) begin
            @(negedge bfm.clk_sys);
        end

        $display("===============Testing SLL with 7-6-5 170-3=================");
        bfm.reset_cpu();
        bfm.setRegisters(7, 6, 5);
        bfm.setArithVals(170,3);
        bfm.init_mem(ALU_SLL);
        bfm.reset_cpu();
        repeat (50) begin
            @(negedge bfm.clk_sys);
        end
*/
        //STOP
        bfm.end_sim();
    endtask : execute

endclass : tester

