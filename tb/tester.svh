/*
The main stimulus class.

This class connects the opcode generator to the rest of the testbench. By
calling "init_mem" it is allowing random data and opcodes to be tested.
*/

import ibex_pkg::*;
class tester;

    virtual vip_bfm bfm;

    function new (virtual vip_bfm b);
        bfm = b;
    endfunction : new
    
    task execute();
        repeat(1000) begin
            // run random operations with random data
            bfm.reset_cpu();
            bfm.init_mem();
            bfm.reset_cpu();
            repeat (50) begin
                @(negedge bfm.clk_sys);
            end
        end
        bfm.end_sim();
    endtask : execute

endclass : tester

