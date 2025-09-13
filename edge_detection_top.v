module edge_detection_top #(
    parameter IMAGE_WIDTH = 128
)(
    input  wire        clk,
    input  wire        reset,
    input  wire [7:0]  image_data,
    input  wire        data_valid,
    output wire [7:0]  edge_output,
    output wire        edge_valid
);

    // Wires to connect the sub-modules
    wire [7:0] sobel_window [0:8];
    wire       window_valid_sig;

    // Instantiate the image buffer
    image_buffer #(
        .IMAGE_WIDTH(IMAGE_WIDTH)
    ) image_buffer_inst (
        .clk(clk),
        .reset(reset),
        .pixel_in(image_data),
        .pixel_valid(data_valid),
        .pixel_window(sobel_window),
        .window_valid(window_valid_sig)
    );

    // Instantiate the Sobel core
    sobel_core sobel_core_inst (
        .clk(clk),
        .reset(reset),
        .pixel_window(sobel_window),
        .window_valid(window_valid_sig),
        .edge_magnitude(edge_output),
        .magnitude_valid(edge_valid)
    );

endmodule
