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
    
    //default to 1MHz
    parameter CLOCK_CYCLE  = 2;
    parameter CLOCK_WIDTH  = CLOCK_CYCLE/2;
    parameter IDLE_CLOCKS  = 10;
    opcode_e op_code;

    parameter int          MEM_SIZE  = 64 * 1024; // 64 kB
    parameter logic [31:0] MEM_START = 32'h00000000;
    parameter logic [31:0] MEM_MASK  = MEM_SIZE-1;
  
    logic clk_sys, rst_sys_n;
  
    // Instruction connection to "RAM"
    logic        instr_req;
    logic        instr_gnt;
    logic        instr_rvalid;
    logic [31:0] instr_addr;
    logic [31:0] instr_rdata;
  
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
       .clk_i                 (clk_sys),
       .rst_ni                (rst_sys_n),
  
       .test_en_i             ('b0),
  
       .hart_id_i             (32'b0),
       // First instruction executed is at 0x0 + 0x80
       .boot_addr_i           (32'h00000000),
  
       .instr_req_o           (instr_req),
       .instr_gnt_i           (instr_gnt),
       .instr_rvalid_i        (instr_rvalid),
       .instr_addr_o          (instr_addr),
       .instr_rdata_i         (instr_rdata),
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
    if (instr_req) begin
      mem_req        = (instr_addr & ~MEM_MASK) == MEM_START;
      mem_addr       = instr_addr;
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
    .clk_i     ( clk_sys        ),
    .rst_ni    ( rst_sys_n      ),
    .req_i     ( mem_req        ),
    .we_i      ( mem_write      ),
    .be_i      ( mem_be         ),
    .addr_i    ( mem_addr       ),
    .wdata_i   ( mem_wdata      ),
    .rvalid_o  ( mem_rvalid     ),
    .rdata_o   ( mem_rdata      )
  );

  // "RAM" to Ibex
  assign instr_rdata    = mem_rdata;
  assign data_rdata     = mem_rdata;
  assign instr_rvalid   = mem_rvalid;
  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      instr_gnt    <= 'b0;
      data_gnt     <= 'b0;
      data_rvalid  <= 'b0;
    end else begin
      instr_gnt    <= instr_req && mem_req;
      data_gnt     <= ~instr_req && data_req && mem_req;
      data_rvalid  <= ~instr_req && data_req && mem_req;
    end
  end
    
    //load data, free running clock
    //TODO: This should be part of the BFM, or some kind of interface
    initial
    begin
        sp_ram.init_basic_memory();
        clk_sys = 1;
        forever #CLOCK_WIDTH clk_sys = ~clk_sys;
    end

    //----------------------------------------------------
    // Monitors  TODO: make a class
    //----------------------------------------------------
    always @(posedge clk_sys) begin
        if ($test$plusargs ("DBG-INSTR")) begin
            $display ($time, "ns; req:%b \t gnt:%b \t rvalid:%b \t addr:%h \t rdata:%h",
            instr_req, instr_gnt, instr_rvalid, instr_addr, instr_rdata);
        end

        if ($test$plusargs ("MON-INSTR")) begin
            $monitor ($time, "ns; req:%b \t gnt:%b \t rvalid:%b \t addr:%h \t rdata:%h",
            instr_req, instr_gnt, instr_rvalid, instr_addr, instr_rdata);
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
        rst_sys_n <= 0;
        repeat (IDLE_CLOCKS) @(negedge clk_sys);
        rst_sys_n <= 1;
        
        repeat (1000) begin
            @(negedge clk_sys);
        end
        
        $stop;
    end : tester

endmodule
