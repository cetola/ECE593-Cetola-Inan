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
    
    opcode_e op_code;

    parameter int          MEM_SIZE  = 64 * 1024; // 64 kB
    parameter logic [31:0] MEM_START = 32'h00000000;
    parameter logic [31:0] MEM_MASK  = MEM_SIZE-1;
  
    vip_bfm bfm();
  
    // Data connection to "RAM"
    logic        data_req;
    logic        data_gnt;
    logic        data_rvalid;
    logic        data_we;
    logic  [3:0] data_be;
    logic [31:0] data_addr;
    logic [31:0] data_wdata;
    logic [31:0] data_rdata;
  
    // "RAM" arbiter
    logic [31:0] mem_addr;
    logic        mem_req;
    logic        mem_write;
    logic  [3:0] mem_be;
    logic [31:0] mem_wdata;
    logic        mem_rvalid;
    logic [31:0] mem_rdata;

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
  
       .data_req_o            (data_req),
       .data_gnt_i            (data_gnt),
       .data_rvalid_i         (data_rvalid),
       .data_we_o             (data_we),
       .data_be_o             (data_be),
       .data_addr_o           (data_addr),
       .data_wdata_o          (data_wdata),
       .data_rdata_i          (data_rdata),
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

    // Connect Ibex to "RAM"
  always_comb begin
    mem_req        = 1'b0;
    mem_addr       = 32'b0;
    mem_write      = 1'b0;
    mem_be         = 4'b0;
    mem_wdata      = 32'b0;
    if (bfm.instr_req) begin
      mem_req        = (bfm.instr_addr & ~MEM_MASK) == MEM_START;
      mem_addr       = bfm.instr_addr;
    end else if (data_req) begin
      mem_req        = (data_addr & ~MEM_MASK) == MEM_START;
      mem_write      = data_we;
      mem_be         = data_be;
      mem_addr       = data_addr;
      mem_wdata      = data_wdata;
    end
  end

  // single port "RAM" block for instruction and data storage
  ram_1p #(
    .Depth(MEM_SIZE / 4)
  ) sp_ram (
    .clk_i     ( bfm.clk_sys        ),
    .rst_ni    ( bfm.rst_sys_n      ),
    .req_i     ( mem_req        ),
    .we_i      ( mem_write      ),
    .be_i      ( mem_be         ),
    .addr_i    ( mem_addr       ),
    .wdata_i   ( mem_wdata      ),
    .rvalid_o  ( mem_rvalid     ),
    .rdata_o   ( mem_rdata      )
  );

  // "RAM" to Ibex
  assign bfm.instr_rdata    = mem_rdata;
  assign data_rdata     = mem_rdata;
  assign bfm.instr_rvalid   = mem_rvalid;
  always_ff @(posedge bfm.clk_sys or negedge bfm.rst_sys_n) begin
    if (!bfm.rst_sys_n) begin
      bfm.instr_gnt    <= 'b0;
      data_gnt     <= 'b0;
      data_rvalid  <= 'b0;
    end else begin
      bfm.instr_gnt    <= bfm.instr_req && mem_req;
      data_gnt     <= ~bfm.instr_req && data_req && mem_req;
      data_rvalid  <= ~bfm.instr_req && data_req && mem_req;
    end
  end
    
    //----------------------------------------------------
    // Monitors  TODO: make a class
    //----------------------------------------------------
    always @(posedge bfm.clk_sys) begin
        if ($test$plusargs ("DBG-INSTR")) begin
            $display ($time, "ns; req:%b \t gnt:%b \t rvalid:%b \t addr:%h \t rdata:%h",
            bfm.instr_req, bfm.instr_gnt, bfm.instr_rvalid, bfm.instr_addr, bfm.instr_rdata);
        end

        if ($test$plusargs ("MON-INSTR")) begin
            $monitor ($time, "ns; req:%b \t gnt:%b \t rvalid:%b \t addr:%h \t rdata:%h",
            bfm.instr_req, bfm.instr_gnt, bfm.instr_rvalid, bfm.instr_addr, bfm.instr_rdata);
        end
        if (mem_rvalid) begin
            $display($time, " MEM-READ  addr=0x%08x value=0x%08x", mem_addr, mem_rdata);
        end
        if (mem_write) begin
            $display($time, " MEM-WRITE addr=0x%08x value=0x%08x", mem_addr, mem_wdata);
        end
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
