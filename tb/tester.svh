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
        repeat(20) begin
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

