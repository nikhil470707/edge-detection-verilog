module sobel_core (
    input  wire        clk,
    input  wire        reset,
    input  wire [7:0]  pixel_window [0:8],
    input  wire        window_valid,
    output reg  [7:0]  edge_magnitude,
    output reg         magnitude_valid
);

    // Internal wires for signed calculations to prevent overflow.
    // The maximum possible value for Gx or Gy is 4 * 255 = 1020, so 11 bits are needed.
    // We use a safe bit width of 16 for all intermediate calculations.
    wire signed [15:0] Gx, Gy;
    wire signed [15:0] Gx_abs, Gy_abs;

    // Sobel Gx kernel: [-1 0 1; -2 0 2; -1 0 1]
    assign Gx = ( $signed(pixel_window[2]) + 
                 ($signed(pixel_window[5]) * 2) + 
                  $signed(pixel_window[8]) ) -
                ( $signed(pixel_window[0]) + 
                 ($signed(pixel_window[3]) * 2) + 
                  $signed(pixel_window[6]) );

    // Sobel Gy kernel: [-1 -2 -1; 0 0 0; 1 2 1]
    assign Gy = ( $signed(pixel_window[6]) + 
                 ($signed(pixel_window[7]) * 2) + 
                  $signed(pixel_window[8]) ) -
                ( $signed(pixel_window[0]) + 
                 ($signed(pixel_window[1]) * 2) + 
                  $signed(pixel_window[2]) );

    // Calculate absolute values of Gx and Gy
    assign Gx_abs = (Gx < 0) ? -Gx : Gx;
    assign Gy_abs = (Gy < 0) ? -Gy : Gy;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            edge_magnitude <= 8'h00;
            magnitude_valid <= 1'b0;
        end else begin
            // Check if the input window is valid
            if (window_valid) begin
                // Calculate the magnitude: |Gx| + |Gy|
                // Clamp the output to an 8-bit value (0-255).
                if ((Gx_abs + Gy_abs) > 255) begin
                    edge_magnitude <= 8'hff;
                end else begin
                    edge_magnitude <= (Gx_abs + Gy_abs);
                end
                magnitude_valid <= 1'b1;
            end else begin
                magnitude_valid <= 1'b0;
            end
        end
    end
endmodule
