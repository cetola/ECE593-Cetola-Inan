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
        repeat (1000) begin
            @(negedge bfm.clk_sys);
        end
        bfm.end_sim();
    endtask : execute
endclass : tester

