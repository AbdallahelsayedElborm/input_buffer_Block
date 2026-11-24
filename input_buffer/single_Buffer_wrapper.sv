

//============================================================
// Module: bram_mux_wrapper
// Description:
// BRAM Banks -> MUX Bank -> Output Registers
//============================================================

module bram_mux_wrapper #(

    parameter int NUM_BRAM   = 14,   // Number of BRAM banks
    parameter int NUM_MUX    = 14,   // Number of multiplexers

    parameter int ADDR_WIDTH = 12,  // BRAM address width
    parameter int DATA_WIDTH = 8,   // Data width

    // Select width to select one of the BRAM banks
    parameter int SEL_W = (NUM_BRAM > 1) ?
                           $clog2(NUM_BRAM) : 1,

    // Total memory size per BRAM in bits
    parameter int MEMORY_SIZE = (1 << ADDR_WIDTH) * DATA_WIDTH

)(
    input logic clk,

    // BRAM control signals
    input logic en,
    input logic we,

    // Common address for all BRAM banks
    input logic [ADDR_WIDTH-1:0] addr,

    // Independent data input for each BRAM
    input logic [DATA_WIDTH-1:0] din [NUM_BRAM],

    // Independent select for each MUX
    input logic [SEL_W-1:0] sel [NUM_MUX],

    // Final registered outputs
    output logic [DATA_WIDTH-1:0] final_out [NUM_MUX]
);


    //========================================================
    // Internal Signals
    //========================================================

    // Outputs of all BRAM banks
    logic [DATA_WIDTH-1:0] bram_out [NUM_BRAM];

    // Inputs of the MUX bank
    // Each MUX receives outputs from all BRAM banks
    logic [DATA_WIDTH-1:0] mux_in [NUM_MUX][NUM_BRAM];

    // Outputs of the MUX bank
    //logic [DATA_WIDTH-1:0] final_out [NUM_MUX];


    //========================================================
    // Stage 1: BRAM Bank
    //========================================================

    my_bram #(
        .M           (NUM_BRAM),
        .ADDR_WIDTH  (ADDR_WIDTH),
        .DATA_WIDTH  (DATA_WIDTH),
        .MEMORY_SIZE (MEMORY_SIZE)
    ) u_bram_bank (

        .clk  (clk),
        .en   (en),
        .we   (we),
        .addr (addr),

        .din  (din),
        .dout (bram_out)
    );


    //========================================================
    // Stage 2: Connect All BRAM Outputs to All MUXes
    //========================================================

    generate

        for (genvar m = 0; m < NUM_MUX; m++) begin : g_mux_inputs

            for (genvar b = 0; b < NUM_BRAM; b++) begin : g_bank_connect

                // BRAM output b goes to MUX m input b
                assign mux_in[m][b] = bram_out[b];

            end

        end

    endgenerate


    //========================================================
    // Stage 3: MUX Bank
    //========================================================

    mux_bank #(
        .M     (NUM_MUX),
        .N     (NUM_BRAM),
        .W     (DATA_WIDTH),
        .SEL_W (SEL_W)
    ) u_mux_bank (

        .in  (mux_in),
        .sel (sel),
        .out (final_out)
    );


    //========================================================
    // Stage 4: Output Registers
    //========================================================

    // // Register each MUX output on the rising clock edge.

    // always_ff @(posedge clk) begin

    //     for (int i = 0; i < NUM_MUX; i++) begin

    //         final_out[i] <= mux_out[i];

    //     end

    // end

endmodule


