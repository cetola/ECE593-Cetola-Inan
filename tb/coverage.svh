/*
The main coverage class.

This class will ensure coverage of a defined set of opcodes and check that the
FSMs are exercised.
*/

class coverage;

    virtual vip_bfm bfm;

    function new (virtual vip_bfm b);
        bfm = b;
    endfunction : new

    //TODO: Stub
    task execute();
    endtask : execute
endclass : coverage

