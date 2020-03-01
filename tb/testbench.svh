class testbench;

    tester    tester_h;
    coverage  coverage_h;
    scoreboard scoreboard_h;

    //TODO: Stub
    function new ();
    endfunction : new

    task execute();
        tester_h    = new();
        coverage_h   = new();
        scoreboard_h = new();

        fork
            tester_h.execute();
            coverage_h.execute();
            scoreboard_h.execute();
        join_none
    endtask : execute
endclass : testbench
