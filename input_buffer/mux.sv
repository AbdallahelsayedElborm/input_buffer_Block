
//============================================================
// Module: mux_gen
// Description: Generic N-to-1 Multiplexer
//============================================================

module mux_gen #(
    parameter int N = 6,  // Number of inputs to the multiplexer
    parameter int W = 8,  // Width of each input data bus

    // Select signal width:
    // $clog2(N) calculates the minimum number of bits
    // required to select one of the N inputs.
    // At least 1 bit is required.
    parameter int SEL_W = (N > 1) ? $clog2(N) : 1  // SEL_W = 3 for N = 6
)(
    input  logic [W-1:0] in [N], // N input words, each W bits wide
                                // Example: N=6, W=8 -> 6 inputs, each 8 bits

    input  logic [SEL_W-1:0] sel, // Select signal determines which input is selected
                                  // Example: SEL_W=3 -> 2^3 = 8 possible values

    output logic [W-1:0] out      // W-bit output containing the selected input
);

    // Combinational logic: output changes whenever inputs or sel change.
    always_comb begin

        // Check whether the select value is within the valid input range.
        // Valid values are from 0 to N-1.
        if (sel < N)

            // Forward the selected input to the output.
            out = in[sel];

        else

            // If sel is out of range, drive the output to zero.
            out = '0;

    end

endmodule


//============================================================
// Module: mux_bank
// Description: Generic bank of M independent multiplexers
//===========================================================

module mux_bank #(
    parameter int M     = 4,   // Number of multiplexers in the bank
    parameter int N     = 6,   // Number of inputs per multiplexer
    parameter int W     = 8,   // Width of each input/output data bus

    // Select signal width for each multiplexer.
    // All multiplexers have the same number of inputs (N).
    parameter int SEL_W = (N > 1) ? $clog2(N) : 1
)(
    // 2D unpacked array:
    // M multiplexers, each containing N inputs of W bits.
    // in[m][n] represents input n of multiplexer m.
    input  logic [W-1:0]     in  [M][N],

    // Each multiplexer has its own independent select signal.
    // sel[m] controls multiplexer number m.
    input  logic [SEL_W-1:0] sel [M],

    // Each multiplexer has its own W-bit output.
    // out[m] is the output of multiplexer m.
    output logic [W-1:0]     out [M]
);

    // Generate M independent multiplexer instances.
    generate
        for (genvar m = 0; m < M; m++) begin : g_lane

            // Instantiate one mux_gen for each lane.
            // Each instance receives:
            //   in[m]  -> N inputs belonging to mux m
            //   sel[m] -> Select signal belonging to mux m
            //   out[m] -> Output of mux m

            mux_gen #(.N(N), .W(W)) u_mux (
                .in  (in[m]),
                .sel (sel[m]),
                .out (out[m])
            );

        end
    endgenerate

endmodule
