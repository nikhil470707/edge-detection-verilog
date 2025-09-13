`timescale 1ns/1ps

module sobel_testbench;

    // Testbench parameters
    localparam IMAGE_WIDTH  = 128;
    localparam IMAGE_HEIGHT = 128;
    localparam CLK_PERIOD   = 10; // 100 MHz clock

    // Signals for the DUT
    reg         clk;
    reg         reset;
    reg  [7:0]  image_data;
    reg         data_valid;
    wire [7:0]  edge_output;
    wire        edge_valid;

    // Internal memory for input and output data
    reg [7:0] image_mem [0:IMAGE_WIDTH*IMAGE_HEIGHT-1];
    integer   pixel_count;
    integer   output_file;

    // Instantiate the top-level design
    edge_detection_top #(
        .IMAGE_WIDTH(IMAGE_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .image_data(image_data),
        .data_valid(data_valid),
        .edge_output(edge_output),
        .edge_valid(edge_valid)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test sequence
    initial begin
        // Open the output file
        output_file = $fopen("output_edges.txt", "w");
        if (output_file == 0) begin
            $display("ERROR: Could not open output file.");
            $finish;
        end

        // Load the input image data
        $readmemh("input_pixels.mem", image_mem);

        // Reset the DUT
        reset <= 1;
        image_data <= 0;
        data_valid <= 0;
        #(2*CLK_PERIOD) reset <= 0;

        // Stream the image data to the DUT
        pixel_count = 0;
        repeat (IMAGE_WIDTH * IMAGE_HEIGHT) begin
            @(posedge clk);
            image_data <= image_mem[pixel_count];
            data_valid <= 1;
            pixel_count <= pixel_count + 1;
        end
        @(posedge clk);
        data_valid <= 0;

        // Wait for all data to be processed and written
        repeat (3*IMAGE_WIDTH) @(posedge clk); // A few extra cycles for pipeline flush

        $display("Simulation finished. Output written to output_edges.txt");
        $fclose(output_file);
        $finish;
    end

    // Monitor and write valid output pixels
    always @(posedge clk) begin
        if (edge_valid) begin
            $fwrite(output_file, "%h\n", edge_output);
        end
    end
endmodule
