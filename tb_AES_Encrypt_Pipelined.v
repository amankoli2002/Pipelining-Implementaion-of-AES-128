`timescale 1ns / 1ps

module tb_AES_Encrypt_Pipelined;

    localparam LATENCY = 11;
    localparam TOTAL_BLOCKS = 10;
    localparam [127:0] KEY = 128'h000102030405063923090a0b0c0d0e0f;

    reg clk;
    reg reset;
    reg start;
    reg [127:0] data_in;
    reg [127:0] key_in;
    wire [127:0] data_out;
    wire done;

    integer error_count = 0;
    integer output_count = 0;

    AES_Encrypt_Pipelined dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .data_in(data_in),
        .key_in(key_in),
        .data_out(data_out),
        .done(done)
    );

    // ---------------------
    // Clock generation (10 ns period)
    // ---------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // ---------------------
    // Wave dump
    // ---------------------
    initial begin
        $dumpfile("aes_pipelined.vcd");
        $dumpvars(0, tb_AES_Encrypt_Pipelined);
    end

    // ---------------------
    // Plaintexts & expected ciphertexts
    // ---------------------
    reg [127:0] P [0:9];
    reg [127:0] C [0:9];

    initial begin
        P[0]=128'h0011223344556677ff99aabbfcddeeff; C[0]=128'h0cdc3c906675d9081510b9083d9c13e3;
        P[1]=128'h0011223344556636ff99aabbfcddeeff; C[1]=128'h6f7571ab88f240311cd4c3d8e2ad62ff;
        P[2]=128'h00112233445f2636ff99aabbfcddeeff; C[2]=128'hdf14d11be6e3f3d6f86cd2175de66106;
        P[3]=128'hf2112233445f2636ff99aabbfcddeeff; C[3]=128'hb5b62f1a635016a44ce4c2daa4239daa;
        P[4]=128'ha2112236445f2636ff99aabbfcddeeff; C[4]=128'h76b02c46fd5bfb3e1ee125c54fd03da8;
        P[5]=128'hb2112236445f2636ff99aabbfcddeeff; C[5]=128'h1b3ebcbfe8c114ce3af55d87d6d7dc21;
        P[6]=128'hb2112236445f2d56ff99aabbfcddeeff; C[6]=128'h92672e2f573216dd383b51fa3228403e;
        P[7]=128'hb2112236445f2d56ff99bdbbfcddeeff; C[7]=128'h1435bbfcb009a0c9b2df9ea7dc396b0c;
        P[8]=128'hb21122364d5f2d56ff99bdbbfcddeeff; C[8]=128'h2512b941c8952934580ce84a0de824fc;
        P[9]=128'hb21122364d5f2d56ff99bdbbfcdd2394; C[9]=128'h97b505f4f5cb3fde737c5c934cf5a056;
    end

    // ---------------------
    // Stimulus (no loops, manual sequence)
    // ---------------------
    initial begin
        reset = 1; start = 0; data_in = 0; key_in = 0;
        #20 reset = 0;
        @(posedge clk); key_in = KEY;

        $display("\n=== AES-128 PIPELINED TEST (inputs before posedge, no loops) ===");

        // Each block driven 2.5 ns before posedge
        #2.5; start=1; data_in=P[0]; @(posedge clk);
        #2.5; start=1; data_in=P[1]; @(posedge clk);
        #2.5; start=1; data_in=P[2]; @(posedge clk);
        #2.5; start=1; data_in=P[3]; @(posedge clk);
        #2.5; start=1; data_in=P[4]; @(posedge clk);
        #2.5; start=1; data_in=P[5]; @(posedge clk);
        #2.5; start=1; data_in=P[6]; @(posedge clk);
        #2.5; start=1; data_in=P[7]; @(posedge clk);
        #2.5; start=1; data_in=P[8]; @(posedge clk);
        #2.5; start=1; data_in=P[9]; @(posedge clk);

        #2.5; start=0; data_in=0;

        $display("[%0t] Finished feeding 10 plaintexts. Waiting for ciphertexts...\n", $time);

        #( (TOTAL_BLOCKS + LATENCY + 5) * 10 );

        $display("\n--- FINAL SUMMARY ---");
        if (error_count == 0 && output_count == TOTAL_BLOCKS)
            $display("✅ All %0d ciphertexts matched expected results!", TOTAL_BLOCKS);
        else
            $display("❌ %0d mismatches detected out of %0d blocks.", error_count, TOTAL_BLOCKS);

        $finish;
    end

    // ---------------------
    // Output check
    // ---------------------
    always @(posedge clk) begin
        if (!reset && done) begin
            if (data_out === C[output_count])
                $display("[%0t] Block %0d correct: %h", $time, output_count, data_out);
            else begin
                $display("[%0t] Block %0d mismatch!", $time, output_count);
                $display("   Got: %h", data_out);
                $display("   Exp: %h", C[output_count]);
                error_count = error_count + 1;
            end
            output_count = output_count + 1;
        end
    end
endmodule
