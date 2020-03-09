/*
The main checker class.

This class will compare values and ensure that an add, subtract, shift, or
logical opporation worked correctly. We look at these on the high level from
the signals provided by the BFM.

TODO: Test load and store from memory.
TODO: High level (white box) verification. Look at the BFM lines and ignore
the registers. This might not verify the ALU functions like ADD or SUB. This
might be useful to check that load and store worked.

*/
import ibex_pkg::*;
class scoreboard;

    virtual vip_bfm bfm;
    /*
    These are handy local variables for checking values. Note that the
    destination register is also one of the other three registers
    */ 
    int reg1, reg2, reg3, regDest;
    int ramVal1, ramVal2, ramVal3;
    int errors;

    function new (virtual vip_bfm b);
        bfm = b;
        errors = 0;
    endfunction : new

    task execute();
        fork
            debugAll();
            checkResult();
            updateValues();
        join
    endtask : execute

    task checkResult();
        forever begin : result_checker
            @(regDest) begin
                repeat(2) @(posedge bfm.clk_sys);
                if(bfm.instr_rvalid) begin
                    case(bfm.currAluOp)
                        ALU_ADD: checkResultAdd();
                        ALU_SUB: checkResultSub();
                        ALU_XOR: checkResultXor();
                        ALU_OR: checkResultOr();
                        ALU_AND: checkResultAnd();
                        ALU_SRL: checkResultSrl();
                        ALU_SLL: checkResultSll();
                        default: throwError($sformatf("Unknown ALU Op: %s",bfm.currAluOp.name));
                    endcase
                end
            end
        end
    endtask : checkResult

    // Test the Add Operation: Grey Box: Low level checking
    task checkResultAdd();
        int result = bfm.testArith1 + bfm.testArith2;
        if(result !== regDest) begin
            throwError($sformatf("ADD ERR: Expected %h but saw %h", result, regDest));
        end
    endtask

    // Test the Subtraction Operation: Grey Box: Low level checking
    task checkResultSub();
        int result = bfm.testArith1 - bfm.testArith2;
        if(result !== regDest) begin
            throwError($sformatf("SUB ERR: Expected %h but saw %h", result, regDest));
        end
    endtask

    // Test the XOR Operation: Grey Box: Low level checking
    task checkResultXor();
        int result = bfm.testArith1 ^ bfm.testArith2;
        if(result !== regDest) begin
            throwError($sformatf("XOR ERR: Expected %h but saw %h", result, regDest));
        end
    endtask

    // Test the OR Operation: Grey Box: Low level checking
    task checkResultOr();
        int result = bfm.testArith1 | bfm.testArith2;
        if(result !== regDest) begin
            throwError($sformatf("OR ERR: Expected %h but saw %h", result, regDest));
        end
    endtask

    // Test the AND Operation: Grey Box: Low level checking
    task checkResultAnd();
        int result = bfm.testArith1 & bfm.testArith2;
        if(result !== regDest) begin
            throwError($sformatf("AND ERR: Expected %h but saw %h", result, regDest));
        end
    endtask

    // Test the SRL Operation: Grey Box: Low level checking
    task checkResultSrl();
        int result = bfm.testArith1 >> bfm.testArith2;
        if(result !== regDest) begin
            throwError($sformatf("SRL ERR: Expected %h but saw %h", result, regDest));
        end
    endtask

    // Test the SLL Operation: Grey Box: Low level checking
    task checkResultSll();
        int result = bfm.testArith1 << bfm.testArith2;
        if(result !== regDest) begin
            throwError($sformatf("SLL ERR: Expected %h but saw %h", result, regDest));
        end
    endtask

    task throwError(input string msg);
        errors = errors +1;
        $display("SCOREBOARD ERR: %s", msg);
    endtask

    // Update local variables with values from registers or RAM
    task updateValues();
        forever begin : self_checker
        @(posedge bfm.clk_sys);
        reg1 = bfm.reg_val(5);
        reg2 = bfm.reg_val(6);
        reg3 = bfm.reg_val(7);
        regDest = bfm.reg_val(bfm.testRegDest);
        ramVal1 = bfm.ram_val(62);
        ramVal2 = bfm.ram_val(63);
        ramVal3 = bfm.ram_val(64);
        end
    endtask

    task debugAll();
        forever begin : self_checker
            @(posedge bfm.clk_sys);
            if ($test$plusargs ("DBG-INSTR")) begin
                $display("Dest Reg %h", regDest);
                $display("Arith 1 %h", bfm.testArith1);
                $display("Arith 2 %h", bfm.testArith2);
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
    endtask : debugAll
endclass : scoreboard
