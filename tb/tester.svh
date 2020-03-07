/*
The main stimulus class.

This class connects the opcode generator to the rest of the testbench. It will
also feed randomized data at some point.
*/


class tester;

    virtual vip_bfm bfm;

    function new (virtual vip_bfm b);
        bfm = b;
    endfunction : new
    
    task execute();
        bfm.init_mem_add();
        bfm.reset_cpu();
        $display("====================Testing Defaults=======================");
        repeat (50) begin
            @(negedge bfm.clk_sys);
        end
        bfm.reset_cpu();
        bfm.setRegisters(6, 7, 5);
        bfm.setArithVals(2, 3);
        bfm.init_mem_add();
        bfm.reset_cpu();
        $display("====================Testing 6-7-5 2-3=======================");
        repeat (50) begin
            @(negedge bfm.clk_sys);
        end
        bfm.end_sim();
    endtask : execute
endclass : tester

