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
    import "DPI-C" function void make_test(input int op, output bit[(64*32-1):0] ram_buf, input int ram_words);
    import "DPI-C" function void initGen();
    import "DPI-C" function void setReg(int r1, int r2, int rd);
    import "DPI-C" function void setArith(int arith1, int arith2);

    typedef enum int
    {
        ARITH_ADD = 32'h0, //R-Type opcode field funct7 and funct3 shown on page 19
        ARITH_SUB = 32'h40000000,
        ARITH_SLL = 32'h00001000,
        ARITH_XOR = 32'h00004000,
        ARITH_SRL = 32'h00005000,
        ARITH_OR = 32'h00006000,
        ARITH_AND = 32'h00007000
    } arithmetic_op_t;

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

    /*
      Opcode Generation Functions

      The following functions connect to the Opcode Generator. This generator
      abstracts out the idea of generating machine code so that the verilog
      can only concern itself with functionality, not ISA implmentation.
    */
    
    // Load a random test into RAM
    function load_test();
        automatic bit [63:0][31:0] ram_buf;
        currAluOp = getRandOp();
        setRandArith();
        $display("===============Testing %s with %h and %h=================",
            currAluOp.name, testArith1, testArith2);
        case(currAluOp)
            ALU_ADD: make_test(ARITH_ADD, ram_buf, 64);
            ALU_SUB: make_test(ARITH_SUB, ram_buf, 64);
            ALU_XOR: make_test(ARITH_XOR, ram_buf, 64);
            ALU_OR: make_test(ARITH_OR, ram_buf, 64);
            ALU_AND: make_test(ARITH_AND, ram_buf, 64);
            ALU_SRL: begin
                setRandArithShift(); 
                make_test(ARITH_SRL, ram_buf, 64);
            end
            ALU_SLL: begin
                setRandArithShift();
                make_test(ARITH_SLL, ram_buf, 64);
            end
            default: throwError($sformatf("Unknown ALU Op: %s",bfm.currAluOp.name));
        endcase
        array_to_ram(ram_buf);
    endfunction

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

    // TODO: test load and store from memory regarless of ALU operation
    function init_mem_loadstore();
        automatic bit [63:0][31:0] ram_buf;
        make_loadstore_test(ram_buf, 64);
        array_to_ram(ram_buf);
    endfunction

    task throwError(input string msg);
        errors = errors +1;
        $display("BFM ERR: %s", msg);
    endtask

    // Setter Functions for Test Registers and Values
    function setRegisters(input int reg1, input int reg2, input int regDest);
        testReg1 = reg1;
        testReg2 = reg2;
        testRegDest = regDest;
        setReg(reg1, reg2, regDest);
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
        setArith(arith1, arith2);
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
        $display("BFM ERR TOTAL: %d", errors);
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

