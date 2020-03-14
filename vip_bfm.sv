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
    
    import "DPI-C" function void make_loadstore_test(output bit[(64*32-1):0] ram_buf, input int ram_words);
    import "DPI-C" function void make_add_test(output bit[(64*32-1):0] ram_buf, input int ram_words);
    import "DPI-C" function void make_sub_test(output bit[(64*32-1):0] ram_buf, input int ram_words);
    import "DPI-C" function void make_xor_test(output bit[(64*32-1):0] ram_buf, input int ram_words);
    import "DPI-C" function void make_and_test(output bit[(64*32-1):0] ram_buf, input int ram_words);
    import "DPI-C" function void make_or_test(output bit[(64*32-1):0] ram_buf, input int ram_words);
    import "DPI-C" function void make_sll_test(output bit[(64*32-1):0] ram_buf, input int ram_words);
    import "DPI-C" function void make_srl_test(output bit[(64*32-1):0] ram_buf, input int ram_words);
    import "DPI-C" function void initGen();
    import "DPI-C" function void setReg1(int val);
    import "DPI-C" function void setReg2(int val);
    import "DPI-C" function void setDestReg(int val);
    import "DPI-C" function void setArith1(int val);
    import "DPI-C" function void setArith2(int val);

    // These values are hard coded in opcode_generator.cpp as defaults
    int testReg1 = 5;
    int testReg2 = 6;
    int testRegDest = 7;
    int testArith1 = 1;
    int testArith2 = 2;

    // Let's not shift 32 bit values more than 31 units as that is unrealistic
    class shft_t;
    rand integer val;
    constraint shft_range { val inside { [0:31]}; }
    endclass

    shft_t shft = new();
    int errors = 0;

    alu_op_e currAluOp;
    opcode_e currOp;
    
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

    // The following functions connect to the Opcode Generator
    // and load instructions directly into the RAM.
    function array_to_ram(input bit [63:0][31:0] ram_buf);
        automatic int i;
        for (i = 0; i < 64; i++)
        begin
            sp_ram.simutil_verilator_set_mem(i, ram_buf[i]);
        end
    endfunction

    function init_mem_loadstore();
        automatic bit [63:0][31:0] ram_buf;
        make_loadstore_test(ram_buf, 64);
        array_to_ram(ram_buf);
    endfunction
    
    function init_mem();
        automatic bit [63:0][31:0] ram_buf;
        currAluOp = getRandOp();
        setRandArith();
        $display("===============Testing %s with %h and %h=================",
            currAluOp.name, testArith1, testArith2);
        case(currAluOp)
            ALU_ADD: make_add_test(ram_buf, 64);
            ALU_SUB: make_sub_test(ram_buf, 64);
            ALU_XOR: make_xor_test(ram_buf, 64);
            ALU_OR: make_or_test(ram_buf, 64);
            ALU_AND: make_and_test(ram_buf, 64);
            ALU_SRL: begin
                setRandArithShift(); 
                make_srl_test(ram_buf, 64);
            end
            ALU_SLL: begin
                setRandArithShift();
                make_sll_test(ram_buf, 64);
            end
            default: throwError($sformatf("Unknown ALU Op: %s",bfm.currAluOp.name));
        endcase
        array_to_ram(ram_buf);
    endfunction

    task throwError(input string msg);
        errors = errors +1;
        $display("BFM ERR: %s", msg);
    endtask

    // Setter Functions for Test Values
    function setRegisters(input int reg1, input int reg2, input int regDest);
        testReg1 = reg1;
        testReg2 = reg2;
        testRegDest = regDest;
        setReg1(reg1);
        setReg2(reg2);
        setDestReg(regDest);
    endfunction

    function setRandArith();
        setArithVals(getRandData(), getRandData());
    endfunction

    function setRandArithShift();
        setArithVals(getRandData(), getRandShift());
    endfunction

    function setArithVals(input int arith1, input int arith2);
        testArith1 = arith1;
        testArith2 = arith2;
        setArith1(arith1);
        setArith2(arith2);
    endfunction

    /*
        Randomization functions
        Both opcodes and data are randomized.
        We should also randomize the registers to ensure they all work.
    */
    function int getRandData();
        bit [1:0] zero_ones;
        zero_ones = $random;
        if(zero_ones === 2'b00)
            return 32'h00;
        else if (zero_ones === 2'b11)
            return 32'hff;
        else
            return $random;
    endfunction

    function int getRandShift();
        shft.randomize();
        return shft.val;
    endfunction

    function alu_op_e getRandOp();
        bit [2:0] op_choice;
        op_choice = $random;
        casez(op_choice)
            3'b000 : return ALU_ADD;
            3'b001 : return ALU_SUB;
            3'b010 : return ALU_XOR;
            3'b011 : return ALU_OR;
            3'b100 : return ALU_AND;
            3'b101 : return ALU_SRL;
            3'b110 : return ALU_SLL;
        endcase
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
        initGen();
        clk_sys = 1;
        forever #CLOCK_WIDTH clk_sys = ~clk_sys;
    end
endinterface : vip_bfm

