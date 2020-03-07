/*
The main checker class.

This class will compare values and ensure that an add, subtract, shift, or
logical opporation worked correctly. We look at these on the high level from
the signals provided by the BFM.

*/

class scoreboard;

    virtual vip_bfm bfm;

    function new (virtual vip_bfm b);
        bfm = b;
    endfunction : new
    //TODO: actually test stuff
    task execute();
        forever begin : self_checker
            @(posedge bfm.clk_sys) 
            if ($test$plusargs ("DBG-INSTR")) begin
                $display("Registers 5, 6, and 7: %h\t%h\t%h", bfm.reg_val(5), bfm.reg_val(6), bfm.reg_val(7));
                $display("RAM 62 and 63: %h  %h", bfm.ram_val(62), bfm.ram_val(63));
            end
            if ($test$plusargs ("DBG-INSTR-V")) begin
                $display ($time, "ns; req:%b \t gnt:%b \t rvalid:%b \t addr:%h \t rdata:%h",
                bfm.instr_req, bfm.instr_gnt, bfm.instr_rvalid, bfm.instr_addr, bfm.instr_rdata);
            end
            if ($test$plusargs ("DBG-MEM")) begin
                if (bfm.mem_rvalid) begin
                    $display($time, " MEM-READ  addr=0x%08x value=0x%08x", bfm.mem_addr, bfm.mem_rdata);
                end
                if (bfm.mem_write) begin
                    $display($time, " MEM-WRITE addr=0x%08x value=0x%08x", bfm.mem_addr, bfm.mem_wdata);
                end
            end
        end : self_checker
    endtask : execute
endclass : scoreboard
