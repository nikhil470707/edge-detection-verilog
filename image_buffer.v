module image_buffer #(
    parameter IMAGE_WIDTH = 128
)(
    input  wire        clk,
    input  wire        reset,
    input  wire [7:0]  pixel_in,
    input  wire        pixel_valid,
    output wire [7:0]  pixel_window [0:8], // 3x3 pixel window output
    output wire        window_valid
);

    // Line buffers to store the previous two lines of the image.
    // The width is configurable.
    reg [7:0] line_buffer_1 [IMAGE_WIDTH-1:0];
    reg [7:0] line_buffer_2 [IMAGE_WIDTH-1:0];

    // Shift registers for the current row to create the 3x3 window.
    reg [7:0] row_sr [2:0];

    // State machine for buffer control and pixel counting.
    reg [15:0] x_count, y_count;

    // Window validity signal.
    reg window_valid_reg;

    // Assigning the output window.
    assign pixel_window[0] = line_buffer_2[x_count-2];
    assign pixel_window[1] = line_buffer_2[x_count-1];
    assign pixel_window[2] = line_buffer_2[x_count];
    assign pixel_window[3] = line_buffer_1[x_count-2];
    assign pixel_window[4] = line_buffer_1[x_count-1];
    assign pixel_window[5] = line_buffer_1[x_count];
    assign pixel_window[6] = row_sr[2];
    assign pixel_window[7] = row_sr[1];
    assign pixel_window[8] = row_sr[0];

    // Assigning the final window validity signal.
    assign window_valid = window_valid_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            x_count <= 0;
            y_count <= 0;
            window_valid_reg <= 1'b0;
            for (integer i=0; i<IMAGE_WIDTH; i=i+1) begin
                line_buffer_1[i] <= 8'h00;
                line_buffer_2[i] <= 8'h00;
            end
            row_sr[0] <= 8'h00;
            row_sr[1] <= 8'h00;
            row_sr[2] <= 8'h00;
        end else if (pixel_valid) begin
            // Shift registers for the current row
            row_sr[2] <= row_sr[1];
            row_sr[1] <= row_sr[0];
            row_sr[0] <= pixel_in;

            // Update column counter
            x_count <= x_count + 1;

            // Check for end of line
            if (x_count == IMAGE_WIDTH - 1) begin
                x_count <= 0;
                y_count <= y_count + 1;
                // Shift line buffers
                for (integer i=0; i<IMAGE_WIDTH; i=i+1) begin
                    line_buffer_2[i] <= line_buffer_1[i];
                    line_buffer_1[i] <= row_sr[0];
                end
            end

            // Set window validity based on position
            if (y_count >= 2 && x_count >= 2) begin
                window_valid_reg <= 1'b1;
            end else begin
                window_valid_reg <= 1'b0;
            end
        end else begin
            window_valid_reg <= 1'b0;
        end
    end
endmodule
