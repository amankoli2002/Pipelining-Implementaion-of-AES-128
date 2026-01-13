module AddRoundKey #(parameter Nk = 4, parameter Nr = 10) (
    input clk,
    input rst,
    input [3:0] roundCount,
    input [127:0] state,
    input [127:0] roundKey,        // current round key (initial key before round 1)
    output [127:0] stateOut,       // output state after AddRoundKey
    //output reg [127:0] nextRoundKey // precomputed next round key (pipelined)
    output [127:0] nextRoundKey
);
    // -----------------------------
    // 1. Perform AddRoundKey
    // -----------------------------
    assign stateOut = state ^ expandedKey;

    // -----------------------------
    // 2. Instantiate pipelined key expansion
    // -----------------------------
    wire [127:0] expandedKey;

    PipelinedKeyExpansionRound #(Nk, Nr) keyExpansionStage (
        .clk(clk),
        .rst(rst),
        .roundCount(roundCount),
        .keyIn(roundKey),       // expand current round key
        .keyOut(expandedKey)    // next round key generated in parallel
    );

    // -----------------------------
    // 3. Pipeline register for next round key
    // -----------------------------
    /*
    always @(posedge clk or posedge rst) begin
        if (rst)
            nextRoundKey <= 128'd0;
        else
            nextRoundKey <= expandedKey;
    end
    */
   assign nextRoundKey = expandedKey;
endmodule
