module sp_ram 
    # (
        parameter ADDR_WIDTH = 32,
        parameter DATA_WIDTH = 32,
        parameter DEPTH = 16 
    )

    (   
        input                   clk_i,
        input                   rst_ni, //ignore reset for now
        input  [ADDR_WIDTH-1:0] addr_i,
        input  [DATA_WIDTH-1:0] wdata_i,
        output [DATA_WIDTH-1:0] rdata_o,
        output                  rvalid_o,
        input                   req_i,
        input                   we_i,
        input   [3:0]           be_i  //ignore byte enable for now
    );

    reg [DATA_WIDTH-1:0]   tmp_data;
    reg [DATA_WIDTH-1:0]   mem [DEPTH];
    reg rvalid;

    always @ (posedge clk_i) begin
        if (we_i) begin
            mem[addr_i] <= wdata_i;
            rvalid <= 0;
        end
    end

    always @ (posedge clk_i) begin
        if (!we_i) begin
            tmp_data <= mem[addr_i];
            rvalid <= 1;
        end
    end

    assign rdata_o = req_i & !we_i ? tmp_data : 'hz;
    assign rvalid_o = req_i & !we_i ? 1 : 0;
endmodule
