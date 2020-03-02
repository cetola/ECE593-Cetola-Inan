/*
Module: toptb.sv
Authors:
Stephano Cetola <cetola@pdx.edu>
SPDX-License-Identifier: MIT
*/
`timescale 1us / 1ns
import ibex_pkg::*;
import vip_pkg::*;
module toptb;
    
    
    vip_bfm bfm();
    testbench    testbench_h;
    
    ibex_core #(
    .DmHaltAddr(32'h00000000),
    .DmExceptionAddr(32'h00000000)
    ) u_core (
    .clk_i                 (bfm.clk_sys),
    .rst_ni                (bfm.rst_sys_n),
    
    .test_en_i             ('b0),
    
    .hart_id_i             (32'b0),
    // First instruction executed is at 0x0 + 0x80
    .boot_addr_i           (32'h00000000),
    
    .instr_req_o           (bfm.instr_req),
    .instr_gnt_i           (bfm.instr_gnt),
    .instr_rvalid_i        (bfm.instr_rvalid),
    .instr_addr_o          (bfm.instr_addr),
    .instr_rdata_i         (bfm.instr_rdata),
    .instr_err_i           ('b0),
    
    .data_req_o            (bfm.data_req),
    .data_gnt_i            (bfm.data_gnt),
    .data_rvalid_i         (bfm.data_rvalid),
    .data_we_o             (bfm.data_we),
    .data_be_o             (bfm.data_be),
    .data_addr_o           (bfm.data_addr),
    .data_wdata_o          (bfm.data_wdata),
    .data_rdata_i          (bfm.data_rdata),
    .data_err_i            ('b0),
    
    .irq_software_i        (1'b0),
    .irq_timer_i           (1'b0),
    .irq_external_i        (1'b0),
    .irq_fast_i            (15'b0),
    .irq_nm_i              (1'b0),
    
    .debug_req_i           ('b0),
    
    .fetch_enable_i        ('b1),
    .core_sleep_o          ()
    );
    
    // single port "RAM" block for instruction and data storage
    ram_1p #(
    .Depth(bfm.MEM_SIZE / 4)
    ) sp_ram (
    .clk_i     ( bfm.clk_sys        ),
    .rst_ni    ( bfm.rst_sys_n      ),
    .req_i     ( bfm.mem_req        ),
    .we_i      ( bfm.mem_write      ),
    .be_i      ( bfm.mem_be         ),
    .addr_i    ( bfm.mem_addr       ),
    .wdata_i   ( bfm.mem_wdata      ),
    .rvalid_o  ( bfm.mem_rvalid     ),
    .rdata_o   ( bfm.mem_rdata      )
    );

    import "DPI-C" function void make_loadstore_test(output bit[(64*32-1):0] ram_buf, input int ram_words);

    function init_mem_loadstore();
        automatic int i;
        automatic bit [63:0][31:0] ram_buf;
        make_loadstore_test(ram_buf, 64);
        for (i = 0; i < 64; i++)
        begin
            //$display("simutil_verilator_set_mem(%d, 0x%x);", i, ram_buf[i]);
            sp_ram.simutil_verilator_set_mem(i, ram_buf[i]);
        end
    endfunction

    initial begin
        init_mem_loadstore();
        testbench_h = new(bfm);
        testbench_h.execute();
     end
    
    //----------------------------------------------------
    // Tester  TODO: make a class
    //----------------------------------------------------
    
    initial begin : tester
        bfm.rst_sys_n <= 0;
        sp_ram.init_basic_memory();
        repeat (bfm.IDLE_CLOCKS) @(negedge bfm.clk_sys);
        bfm.rst_sys_n <= 1;
        
        repeat (1000) begin
            @(negedge bfm.clk_sys);
        end
        
        $stop;
    end : tester
    
endmodule
