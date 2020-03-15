/*
The main stimulus class.

This class connects the opcode generator to the rest of the testbench. By
calling "init_mem" it is allowing random data and opcodes to be tested.
*/


/*
    Opcode Generation Functions

    The following functions connect to the Opcode Generator. This generator
    abstracts out the idea of generating machine code so that the verilog
    can only concern itself with functionality, not ISA implmentation.
*/
import "DPI-C" function void make_test(input int op, output bit[(64*32-1):0] ram_buf, input int ram_words);
import "DPI-C" function void initGen();
import "DPI-C" function void setReg(int r1, int r2, int rd);
import "DPI-C" function void setArith(int arith1, int arith2);


import ibex_pkg::*;
class tester;

    // Opcodes as defined by the RISC-V ISA Spec
    // Ideally we should decouple these so the verilog doesn't need to know how
    // the ISA works. Leave that to the C code.
    typedef enum int
    {
        ARITH_ADD = 32'h0,
        ARITH_SUB = 32'h40000000,
        ARITH_SLL = 32'h00001000,
        ARITH_XOR = 32'h00004000,
        ARITH_SRL = 32'h00005000,
        ARITH_OR = 32'h00006000,
        ARITH_AND = 32'h00007000
    } arithmetic_op_t;

    // Keep shift values between 0 and 31
    rand integer shftVal;
    constraint shft_range { shftVal inside { [0:31]}; }
    
    int errors;
    virtual vip_bfm bfm;

    function new (virtual vip_bfm b);
        initGen();
        errors = 0;
        bfm = b;
    endfunction : new
    
    task execute();
        repeat(1000) begin
            load_test();
            bfm.reset_cpu();
            repeat (50) begin
                @(negedge bfm.clk_sys);
            end
        end
        $display("TESTER ERR TOTAL: %d", errors);
        bfm.end_sim();
    endtask : execute

    /*
        Main Opcode tester.

        This calls the randomization functions and then passes off the task
        of creating machine code to the Opcode Generator. In this way, we
        know which values we should test against in the scoreboard, but we
        do not need to know about how the ISA is formatted.
    */
    function load_test();
        automatic bit [63:0][31:0] ram_buf;
        bfm.test1 = getRandData();
        bfm.test2 = getRandData();
        bfm.currAluOp = getRandOp();
        setArith(bfm.test1, bfm.test2);
        $display("===============Testing %s with %h and %h=================",
            bfm.currAluOp.name, bfm.test1, bfm.test2);
        case(bfm.currAluOp)
            ALU_ADD: make_test(ARITH_ADD, ram_buf, 64);
            ALU_SUB: make_test(ARITH_SUB, ram_buf, 64);
            ALU_XOR: make_test(ARITH_XOR, ram_buf, 64);
            ALU_OR: make_test(ARITH_OR, ram_buf, 64);
            ALU_AND: make_test(ARITH_AND, ram_buf, 64);
            ALU_SRL: begin
                bfm.test2 = getRandShift();
                setArith(bfm.test1, bfm.test2);
                make_test(ARITH_SRL, ram_buf, 64);
            end
            ALU_SLL: begin
                bfm.test2 = getRandShift();
                setArith(bfm.test1, bfm.test2);
                make_test(ARITH_SLL, ram_buf, 64);
            end
            default: throwError($sformatf("Unknown ALU Op: %s",bfm.currAluOp.name));
        endcase
        bfm.array_to_ram(ram_buf);
    endfunction

    /*
        Randomization functions
        Both opcodes and data are randomized.
        TODO: Randomize the registers to ensure they all work.
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
        randomize();
        return shftVal;
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
            default : return ALU_ADD;
        endcase
    endfunction

    task throwError(input string msg);
        errors = errors +1;
        $display("TESTER ERR: %s", msg);
    endtask

endclass : tester

