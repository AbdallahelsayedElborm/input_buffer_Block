//==============================================================================
// Module: multi_input_buffer
// Description:
//   Top-level multi-buffer wrapper instantiating N parallel units of
//   'bram_mux_wrapper'. Provides registered dual output paths for accurate
//   Static Timing Analysis (STA):
//     1. Registered Direct Unicast outputs from every buffer unit (unicast_data).
//     2. Registered Multiplexed Broadcast output selecting one unit (broadcast_data).
//==============================================================================

module multi_input_buffer__reg #(
    // Architecture & Buffer Array Dimensions
    parameter int NUM_BUFFERS = 2,   // Number of parallel buffer units (N)
    parameter int NUM_BRAM    = 14,  // Number of BRAM banks per buffer unit
    parameter int NUM_MUX     = 14,  // Number of internal multiplexers per unit

    // Memory & Datapath Widths
    parameter int ADDR_WIDTH  = 12,  // BRAM address bus width
    parameter int DATA_WIDTH  = 8,   // Data word width in bits

    // Derived Multiplexer Select Signal Widths
    parameter int SEL_W       = (NUM_BRAM > 1)    ? $clog2(NUM_BRAM)    : 1,
    parameter int BCAST_SEL_W = (NUM_BUFFERS > 1) ? $clog2(NUM_BUFFERS) : 1
)(
    // Global Clock & Shared BRAM Control Signals
    input  logic clk,
    input  logic en,
    input  logic we,
    input  logic [ADDR_WIDTH-1:0] addr,

    // Independent Write Data Inputs for each BRAM bank across all buffer units
    input  logic [DATA_WIDTH-1:0] din [NUM_BUFFERS][NUM_BRAM],

    // Internal MUX Select Controls for each individual buffer unit
    input  logic [SEL_W-1:0] sel [NUM_BUFFERS][NUM_MUX],

    // Broadcast MUX Select Control to route one active buffer unit to broadcast_data
    input  logic [BCAST_SEL_W-1:0] bcast_sel,

    // Primary Output 1: Registered Direct Unicast Data Path
    output logic [DATA_WIDTH-1:0] unicast_data   [NUM_BUFFERS][NUM_MUX],

    // Primary Output 2: Registered Multiplexed Broadcast Data Path
    output logic [DATA_WIDTH-1:0] broadcast_data [NUM_MUX]
);

    //==========================================================================
    // Internal Signals
    //==========================================================================
    
    // Aggregates the combinational 'final_out' buses from all instantiated buffer units
    logic [DATA_WIDTH-1:0] unit_out [NUM_BUFFERS][NUM_MUX];

    //==========================================================================
    // Stage 1: Parallel Single-Buffer Instantiation Array
    //==========================================================================
    // Generates NUM_BUFFERS instances of bram_mux_wrapper, each operating on
    // its dedicated slice of input data (din) and internal select lines (sel).
    generate
        for (genvar i = 0; i < NUM_BUFFERS; i++) begin : g_multi_buffer
            bram_mux_wrapper #(
                .NUM_BRAM   (NUM_BRAM),
                .NUM_MUX    (NUM_MUX),
                .ADDR_WIDTH (ADDR_WIDTH),
                .DATA_WIDTH (DATA_WIDTH)
            ) u_single_buffer (
                .clk       (clk),
                .en        (en),
                .we        (we),
                .addr      (addr),
                .din       (din[i]),
                .sel       (sel[i]),
                .final_out (unit_out[i])
            );
        end
    endgenerate

    //==========================================================================
    // Stage 2: Registered Dual Output Stage (For Timing Analysis)
    //==========================================================================
    // Samples both the Unicast array and the Broadcast MUX output on the rising
    // edge of clk to isolate internal datapath timing from top-level I/O pins.
    always_ff @(posedge clk) begin
        // Register all Unicast output buses
        for (int i = 0; i < NUM_BUFFERS; i++) begin
            for (int j = 0; j < NUM_MUX; j++) begin
                unicast_data[i][j] <= unit_out[i][j];
            end
        end

        // Register the selected Broadcast MUX output bus
        for (int j = 0; j < NUM_MUX; j++) begin
            broadcast_data[j] <= unit_out[bcast_sel][j];
        end
    end

endmodule