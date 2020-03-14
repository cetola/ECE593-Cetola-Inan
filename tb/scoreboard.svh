/*
The main checker class.

This class compares values and ensure that an add, subtract, shift, or logical
opporation worked correctly. We look at these on the high level from the
signals provided by the BFM.

Most of the debugging also lives here, especially if the operations fail. Some
additional debugging is available in the BFM.

TODO: High level (white box) verification. Look at the BFM lines and ignore the
registers.

*/
import ibex_pkg::*;
class scoreboard;

    virtual vip_bfm bfm;
    /*
    These are handy local variables for checking values, mostly for debugging.
    The destination register is also one of the other three registers, however
    since it can be randomized, we want to know which register is the dest.
    */ 
    int reg1, reg2, reg3, regDest;
    int ramVal1, ramVal2, ramVal3;
    int errors;
    int success;

    function new (virtual vip_bfm b);
        bfm = b;
        errors = 0;
        success = 0;
    endfunction : new

    task execute();
        fork
            debugAll();
            checkResult();
            updateValues();
        join
    endtask : execute

    // Main Results checker. Depending on the opcode, this checks for the
    // appropriate result.
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

    /*
        Note: It would be really nice to abstract all these tests out so that
        one function could check the op based on the opcode. However, time
        constraints made that hard. We want to display things differently
        based on if we are testing an ADD or SLL, so it was quicker to simply
        use different functions for each. Obviously, not scalable. 
    */

    // Test the Add Operation: Grey Box: Low level checking
    task checkResultAdd();
        int result = bfm.test1 + bfm.test2;
        if(result !== regDest) begin
            throwError($sformatf("ADD ERR: Expected %h but saw %h", result, regDest));
        end
        else if ($test$plusargs ("DBG-INSTR")) begin
            logSuccess($sformatf("Executed: %d + %d = %d successfully", bfm.test1, bfm.test2, result));
        end
    endtask

    // Test the Subtraction Operation: Grey Box: Low level checking
    task checkResultSub();
        int result = bfm.test1 - bfm.test2;
        if(result !== regDest) begin
            throwError($sformatf("SUB ERR: Expected %h but saw %h", result, regDest));
        end
        else if ($test$plusargs ("DBG-INSTR")) begin
            logSuccess($sformatf("Executed: %d - %d = %d successfully", bfm.test1, bfm.test2, result));
        end
    endtask

    // Test the XOR Operation: Grey Box: Low level checking
    task checkResultXor();
        int result = bfm.test1 ^ bfm.test2;
        if(result !== regDest) begin
            throwError($sformatf("XOR ERR: Expected %h but saw %h", result, regDest));
        end
        else if ($test$plusargs ("DBG-INSTR")) begin
            logSuccess($sformatf("Executed: %b ^ %b = %b successfully", bfm.test1, bfm.test2, result));
        end
    endtask

    // Test the OR Operation: Grey Box: Low level checking
    task checkResultOr();
        int result = bfm.test1 | bfm.test2;
        if(result !== regDest) begin
            throwError($sformatf("OR ERR: Expected %h but saw %h", result, regDest));
        end
        else if ($test$plusargs ("DBG-INSTR")) begin
            logSuccess($sformatf("Executed: %b | %b = %b successfully", bfm.test1, bfm.test2, result));
        end
    endtask

    // Test the AND Operation: Grey Box: Low level checking
    task checkResultAnd();
        int result = bfm.test1 & bfm.test2;
        if(result !== regDest) begin
            throwError($sformatf("AND ERR: Expected %h but saw %h", result, regDest));
        end
        else if ($test$plusargs ("DBG-INSTR")) begin
            logSuccess($sformatf("Executed: %b & %b = %b successfully", bfm.test1, bfm.test2, result));
        end
    endtask

    // Test the SRL Operation: Grey Box: Low level checking
    task checkResultSrl();
        int result = bfm.test1 >> bfm.test2;
        if(result !== regDest) begin
            throwError($sformatf("SRL ERR: Expected %h but saw %h", result, regDest));
        end
        else if ($test$plusargs ("DBG-INSTR")) begin
            logSuccess($sformatf("Executed: %b >> %b = %b successfully", bfm.test1, bfm.test2, result));
        end
    endtask

    // Test the SLL Operation: Grey Box: Low level checking
    task checkResultSll();
        int result = bfm.test1 << bfm.test2;
        if(result !== regDest) begin
            throwError($sformatf("SLL ERR: Expected %h but saw %h", result, regDest));
        end
        else if ($test$plusargs ("DBG-INSTR")) begin
            logSuccess($sformatf("Executed: %b << %b = %b successfully", bfm.test1, bfm.test2, result));
        end
    endtask

    task throwError(input string msg);
        errors = errors +1;
        $display("SCOREBOARD ERR: %s", msg);
        $display("SCOREBOARD TOTALS: ERR: %d SUCCESS: %d",errors, success);
    endtask

    task logSuccess(input string msg);
        success = success +1;
        $display("SCOREBOARD: %s", msg);
        $display("SCOREBOARD TOTALS: ERR: %d SUCCESS: %d",errors, success);
    endtask

    // Update local variables with values from registers or RAM
    task updateValues();
        forever begin : self_checker
        @(posedge bfm.clk_sys);
        reg1 = bfm.reg_val(5);
        reg2 = bfm.reg_val(6);
        reg3 = bfm.reg_val(7);
        regDest = bfm.reg_val(7); //TODO: hardcoded for now, not testing regs
        ramVal1 = bfm.ram_val(62);
        ramVal2 = bfm.ram_val(63);
        ramVal3 = bfm.ram_val(64);
        end
    endtask

    task debugAll();
        forever begin : self_checker
            @(posedge bfm.clk_sys);
            if ($test$plusargs ("DBG-INSTR-V")) begin
                $display("rd:%h\tr1:%h\tr2:%hr3:%h\tarith1:%h\tarith2:%h",
                        regDest, reg1, reg2, reg3, bfm.test1, bfm.test2);
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
