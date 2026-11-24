//==============================================================================
// Module: multi_input_buffer
// Description:
//   Top-level multi-buffer wrapper instantiating N parallel units of
//   'bram_mux_wrapper'. Provides dual output paths matching the target
//   dataflow architecture:
//     1. Direct Unicast outputs from every buffer unit (unicast_data).
//     2. Multiplexed Broadcast output selecting one buffer unit (broadcast_data).
//==============================================================================

module multi_input_buffer #(
    // Architecture & Buffer Array Dimensions
    parameter int NUM_BUFFERS = 4,   // Number of parallel buffer units (N)
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

    // Primary Output 1: Direct Unicast Data Path (bypasses top-level broadcast MUX)
    output logic [DATA_WIDTH-1:0] unicast_data   [NUM_BUFFERS][NUM_MUX],

    // Primary Output 2: Multiplexed Broadcast Data Path (selected via bcast_sel)
    output logic [DATA_WIDTH-1:0] broadcast_data [NUM_MUX]
);

    //==========================================================================
    // Internal Signals
    //==========================================================================
    
    // Aggregates the 'final_out' buses from all instantiated single buffer units
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
    // Stage 2: Dual Output Routing (Unicast & Broadcast)
    //==========================================================================

    // Direct Unicast Path: Exposes all buffer unit outputs simultaneously
    assign unicast_data = unit_out;

    // Broadcast MUX Path: Selects a single buffer unit output based on bcast_sel
    assign broadcast_data = unit_out[bcast_sel];

endmodule
