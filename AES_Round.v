// AES_Round_Pipelined.v
// AES Round with integrated pipelined AddRoundKey and next key generation
module AES_Round #(parameter Nk = 4, parameter Nr = 10)(
    input clk,
    input rst,
    input [3:0] roundCount,
    input [127:0] state_in,
    input [127:0] round_key,       // current round key
    input last_round,              // 1 if this is the last AES round
    output [127:0] state_out,      // output after AddRoundKey
    output [127:0] next_round_key  // precomputed next key
);

    // -----------------------------
    // AES transformations (combinational)
    // -----------------------------
    wire [127:0] sub_bytes, shift_rows, mix_columns;

    // SubBytes
    SubBytes sb(
        .oriBytes(state_in),
        .subBytes(sub_bytes)
    );

    // ShiftRows
    ShiftRows sr(
        .in(sub_bytes),
        .out(shift_rows)
    );

    // MixColumns (skipped in last round)
    MixColumns mc(
        .stateIn(shift_rows),
        .stateOut(mix_columns)
    );

    // -----------------------------
    // Pipelined AddRoundKey + Key Expansion
    // -----------------------------
    wire [127:0] add_input_state = last_round ? shift_rows : mix_columns;

    AddRoundKey #(Nk, Nr) add_round_key_stage (
        .clk(clk),
        .rst(rst),
        .roundCount(roundCount),
        .state(add_input_state),
        .roundKey(round_key),
        .stateOut(state_out),
        .nextRoundKey(next_round_key)
    );

endmodule
