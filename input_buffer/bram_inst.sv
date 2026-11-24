
//============================================================
// Module: my_bram
// Description: Generic BRAM Bank using Xilinx XPM Memory
//============================================================

module my_bram #(

    parameter int M           = 4,       // Number of BRAM instances
                                          // Generate M independent BRAMs

    parameter int ADDR_WIDTH  = 12,      // Address bus width
                                          // Number of memory locations = 2^ADDR_WIDTH

    parameter int DATA_WIDTH  = 8,       // Data width of each memory location
                                          // Each location stores DATA_WIDTH bits

    // Total memory capacity in bits:
    // Number of locations * Number of bits per location
    // Example: 2^12 * 8 = 32768 bits = 32 Kbits
    parameter int MEMORY_SIZE = (1 << ADDR_WIDTH) * DATA_WIDTH

)(
    input  logic clk,                    // Clock signal shared by all BRAMs
    input  logic en,                     // Memory enable shared by all BRAMs
    input  logic we,                     // Write enable shared by all BRAMs

    input  logic [ADDR_WIDTH-1:0] addr,  // Common address bus for all BRAMs

    // Independent data input for each BRAM
    // din[i] is the data written into BRAM number i
    input  logic [DATA_WIDTH-1:0] din  [M],

    // Independent data output from each BRAM
    // dout[i] is the data read from BRAM number i
    output logic [DATA_WIDTH-1:0] dout [M]
);


    //========================================================
    // Generate Block
    // Creates M independent XPM Single-Port RAM instances
    //========================================================

    generate
        for (genvar i = 0; i < M; i++) begin : g_bram

            //================================================
            // XPM Memory Configuration
            //================================================

            xpm_memory_spram #(

                // Address width:
                // Determines the number of memory locations.
                // Example: ADDR_WIDTH = 12 -> 4096 locations.
                .ADDR_WIDTH_A       (ADDR_WIDTH),

                // Total memory capacity in bits.
                .MEMORY_SIZE        (MEMORY_SIZE),

                // Select Block RAM as the memory implementation.
                .MEMORY_PRIMITIVE   ("block"),

                // Width of data read from memory.
                .READ_DATA_WIDTH_A  (DATA_WIDTH),

                // Width of data written into memory.
                .WRITE_DATA_WIDTH_A (DATA_WIDTH),

                // Number of bits controlled by each write enable bit.
                // DATA_WIDTH = 8 -> one write enable controls 8 bits.
                .BYTE_WRITE_WIDTH_A (DATA_WIDTH),

                // Read latency = 1 clock cycle.
                .READ_LATENCY_A     (1),

                // Read-first:
                // During a simultaneous read and write to the same
                // address, the output returns the old stored data.
                .WRITE_MODE_A       ("read_first"),

                // Disable Error Correction Code.
                .ECC_MODE           ("no_ecc"),

                // Disable automatic sleep functionality.
                .AUTO_SLEEP_TIME    (0),

                // No external initialization file.
                .MEMORY_INIT_FILE   ("none"),

                // Initialization parameter.
                .MEMORY_INIT_PARAM  ("0"),

                // Enable memory initialization support.
                .USE_MEM_INIT       (1),

                // Disable MMI initialization.
                .USE_MEM_INIT_MMI   (0),

                // Disable sleep wakeup delay.
                .WAKEUP_TIME        ("disable_sleep"),

                // Synchronous reset mode.
                .RST_MODE_A         ("SYNC"),

                // Output value during reset.
                .READ_RESET_VALUE_A ("0"),

                // Automatic BRAM cascade height.
                .CASCADE_HEIGHT     (0),

                // Disable additional XPM messages.
                .MESSAGE_CONTROL    (0),

                // Enable simulation assertion checks.
                .SIM_ASSERT_CHK     (1)

            ) xpm_memory_spram_inst (

                //============================================
                // XPM Port Connections
                //============================================

                .clka  (clk),          // Clock input

                .ena   (en),           // Enable memory access

                .wea   (we),           // Write enable

                .addra (addr),         // Common address for all BRAMs

                // Each BRAM receives its own independent data.
                .dina  (din[i]),

                // Each BRAM produces its own independent output.
                .douta (dout[i]),

                // Output register enable.
                .regcea (1'b1),

                // Reset input (inactive).
                .rsta   (1'b0),

                // Sleep control (inactive).
                .sleep  (1'b0),

                // Disable single-bit error injection.
                .injectsbiterra (1'b0),

                // Disable double-bit error injection.
                .injectdbiterra (1'b0),

                // Single-bit error indicator (unused).
                .sbiterra (),

                // Double-bit error indicator (unused).
                .dbiterra ()

            );

        end
    endgenerate

endmodule
