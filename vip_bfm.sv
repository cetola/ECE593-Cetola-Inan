/*
This BFM separates out the signals that will be used by the testebench classes
and provides a way of observing the DUT.
*/

`timescale 1us / 1ns
import ibex_pkg::*;
interface vip_bfm;
    
    //default to 1MHz
    parameter CLOCK_CYCLE  = 2;
    parameter CLOCK_WIDTH  = CLOCK_CYCLE/2;
    parameter IDLE_CLOCKS  = 10;

    parameter int          MEM_SIZE  = 64 * 1024; // 64 kB
    parameter logic [31:0] MEM_START = 32'h00000000;
    parameter logic [31:0] MEM_MASK  = MEM_SIZE-1;

    alu_op_e currAluOp;
    opcode_e currOp;
    int test1, test2;
    
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
    
    // Since the generator returns an array, use the verilator function to
    // "write" that into memory. Note that we're taking advantage of a
    // pre-made function of Ibex, which uses verilator:
    // https://en.wikipedia.org/wiki/Verilator
    // Instead, we have our own code generator which is much simpler.
    function array_to_ram(input bit [63:0][31:0] ram_buf);
        automatic int i;
        for (i = 0; i < 64; i++)
        begin
            sp_ram.simutil_verilator_set_mem(i, ram_buf[i]);
        end
    endfunction

    // Memory and Register Access Methods
    function int reg_val(input int reg_num);
        reg_val = toptb.u_core.id_stage_i.registers_i.rf_reg[reg_num];
    endfunction

    function int ram_val(input int ram_addr);
        ram_val = sp_ram.mem[ram_addr];
    endfunction

    // Testbench functions for controlling the CPU
    task reset_cpu;
        rst_sys_n <= 0;
        repeat (IDLE_CLOCKS) @(negedge clk_sys);
        rst_sys_n <= 1;
    endtask

    task end_sim;
        $stop;
    endtask
    
    // Free running clock and init basic values for generator
    initial
    begin
        clk_sys = 1;
        forever #CLOCK_WIDTH clk_sys = ~clk_sys;
    end
endinterface : vip_bfm

