module PipelinedKeyExpansionRound #(parameter Nk = 4, parameter Nr = 10) (
    input clk,
    input rst,
    input [3:0] roundCount,
    input [32 * Nk - 1:0] keyIn,
    //output reg [32 * Nk - 1:0] keyOut
    output [32*Nk - 1:0] keyOut
);
    // Split the key into Nk words (each 32 bits)
    wire [31:0] words [Nk - 1:0];
    genvar i;
    generate
        for (i = 0; i < Nk; i = i + 1) begin : KeySplitLoop
            assign words[i] = keyIn[(32 * Nk - 1) - i * 32 -: 32];
        end
    endgenerate

    // Rotate the last word (RotWord)
    wire [31:0] w3Rot = {words[Nk - 1][23:0], words[Nk - 1][31:24]};

    // Apply SubWord using S-Box (SubTable)
    wire [31:0] w3Sub;
    generate
        for (i = 0; i < 4; i = i + 1) begin : SubWordLoop
            SubTable subTable(.oriByte(w3Rot[8 * i +: 8]), .subByte(w3Sub[8 * i +: 8]));
        end
    endgenerate

    // Round Constant (Rcon)
    wire [7:0] roundConstantStart = roundCount == 1 ? 8'h01 :
                                    roundCount == 2 ? 8'h02 :
                                    roundCount == 3 ? 8'h04 :
                                    roundCount == 4 ? 8'h08 :
                                    roundCount == 5 ? 8'h10 :
                                    roundCount == 6 ? 8'h20 :
                                    roundCount == 7 ? 8'h40 :
                                    roundCount == 8 ? 8'h80 :
                                    roundCount == 9 ? 8'h1b :
                                    roundCount == 10 ? 8'h36 :
                                    8'h00;

    wire [31:0] roundConstant = {roundConstantStart, 24'h000000};

    // Calculate first new word
    wire [31:0] new_w0 = words[0] ^ w3Sub ^ roundConstant;

    // Remaining new words
    wire [31:0] new_w1 = words[1] ^ new_w0;
    wire [31:0] new_w2 = words[2] ^ new_w1;
    wire [31:0] new_w3 = words[3] ^ new_w2;

    wire [127:0] nextKey = {new_w0, new_w1, new_w2, new_w3};

    // Pipelined register: keyOut is updated each clock
    /*
    always @(posedge clk or posedge rst) begin
        if (rst)
            keyOut <= 0;
        else
            keyOut <= nextKey;
    end
    */
   assign keyOut = nextKey;
endmodule
