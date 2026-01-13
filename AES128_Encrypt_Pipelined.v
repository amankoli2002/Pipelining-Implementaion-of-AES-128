// AES_Encrypt_Pipelined.v
// Fully pipelined AES-128 encryption (key expansion per round inside AddRoundKeyPipeline)

module AES_Encrypt_Pipelined(
    input clk,
    input reset,
    input start,
    input [127:0] data_in,
    input [127:0] key_in,
    output reg [127:0] data_out,
    output reg done
);

localparam Nk = 4;
localparam Nr = 10;

// ---------------------
// Internal Registers
// ---------------------
reg [3:0] roundCount [0:Nr];         // round index per stage
reg [127:0] state_reg [0:Nr];        // pipeline registers for AES state
reg [127:0] round_key_reg [0:Nr];    // pipeline registers for round keys
reg valid_reg [0:Nr];                // validity flags

wire [127:0] state_next [0:Nr-1];    // intermediate stage outputs
wire [127:0] next_round_key [0:Nr-1];// next round key outputs

integer i;

// ---------------------
// AES Rounds (combinational)
// ---------------------
genvar r;
generate
    for (r = 0; r < Nr; r = r + 1) begin: AES_ROUND_PIPE
        AES_Round #(Nk, Nr) round_inst (
            .clk(clk),
            .rst(reset),
            .roundCount(roundCount[r]),
            .state_in(state_reg[r]),
            .round_key(round_key_reg[r]),
            .last_round((r == Nr-1) ? 1'b1 : 1'b0),
            .state_out(state_next[r]),
            .next_round_key(next_round_key[r])
        );
    end
endgenerate

// ---------------------
// Sequential Pipeline Register Logic (FIXED)
// ---------------------
always @(posedge clk or posedge reset) begin
    if (reset) begin
        data_out <= 0;
        done <= 0;
        for (i = 0; i <= Nr; i = i + 1) begin
            state_reg[i] <= 0;
            round_key_reg[i] <= 0;
            valid_reg[i] <= 0;
            roundCount[i] <= 0;
        end
    end else begin

        // -----------------------------------------
        // Handle output (from stage Nr)
        // -----------------------------------------
        // Data is valid if the *last* stage register was valid on this clock edge.
        // This must be checked *before* the registers are shifted.
        if (valid_reg[Nr]) begin
            data_out <= state_reg[Nr];
            done <= 1'b1; // 'done' acts as 'data_out_valid'
        end else begin
            done <= 1'b0;
        end

        // -----------------------------------------
        // SHIFT PIPELINE (Stages 1 to Nr)
        // -----------------------------------------
        // Shift data and validity from stage i-1 to i
        for (i = Nr; i >= 1; i = i - 1) begin
            state_reg[i]     <= state_next[i-1];
            round_key_reg[i] <= next_round_key[i-1];
            roundCount[i]    <= roundCount[i-1] + 1; // roundCount also shifts
            valid_reg[i]     <= valid_reg[i-1];     // FIX: Shift the valid bit
        end

        // -----------------------------------------
        // Inject new block into pipeline (Stage 0)
        // -----------------------------------------
        // FIX: Injection depends only on 'start', not '!valid_reg[0]'
        if (start) begin
            state_reg[0]     <= data_in ^ key_in; // initial AddRoundKey
            round_key_reg[0] <= key_in;
            roundCount[0]    <= 4'd1;           // first round count
            valid_reg[0]     <= 1'b1;
        end else begin
            // If no new data is starting, stage 0 becomes invalid
            valid_reg[0] <= 1'b0;
        end

    end
end

endmodule
