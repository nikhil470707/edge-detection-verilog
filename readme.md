# **Sobel Edge Detection**

This project implements a hardware-accelerated Sobel edge detection pipeline using Verilog, designed for synthesis on an FPGA. A Python script is provided to handle the full workflow: preparing a test image, running the Verilog simulation, and validating the results against an OpenCV reference implementation.

## **Project Files**

* image\_buffer.v: Implements the line buffers and 3x3 window extraction logic.  
* sobel\_core.v: Contains the combinational logic for the Sobel convolution and magnitude calculation.  
* edge\_detection\_top.v: The top-level module connecting the core components.  
* sobel\_testbench.v: A testbench that streams pixel data from a file, simulates the design, and writes the output to a file.  
* sobel\_validator.py: The main script for the entire validation process.  
* README.md: This file.

## **Prerequisites**

To run this project, you need the following installed:

1. **Icarus Verilog**: A free Verilog simulator. Install it using a package manager (sudo apt-get install iverilog on Linux) or from its official website.  
2. **Python 3**: With the following libraries:  
   * numpy: pip install numpy  
   * opencv-python: pip install opencv-python  
   * matplotlib: pip install matplotlib

## **How to Run**

1. **Download or Create a Grayscale Image**: The sobel\_validator.py script is configured to use a file named test\_image.png. You can use your own image by renaming it to test\_image.png and placing it in the same directory as the script. For best results, use a grayscale image. The script will handle conversion if it's a color image.  
   * **Note**: The current Verilog testbench is configured for a 128x128 image. For a different size, you must change the IMAGE\_WIDTH and IMAGE\_HEIGHT parameters in sobel\_testbench.v, image\_buffer.v, and sobel\_validator.py.  
2. **Run the Validation Script**: Open your terminal or command prompt, navigate to the project directory, and run the Python script:  
   python sobel\_validator.py

3. **View the Output**: The script will automatically:  
   * Generate input\_pixels.mem and output\_edges.txt.  
   * Compile and run the Verilog simulation.  
   * Reconstruct the output image from output\_edges.txt.  
   * Display a side-by-side comparison of the original, Verilog, and OpenCV outputs.  
   * Print the Mean Squared Error (MSE) to quantify the difference between the two outputs.

## **Expected Output**

Upon running the script, a window will pop up displaying the three images, and the terminal will show the MSE and PSNR metrics. The Verilog output should be visually very similar to the OpenCV output, with a very low MSE.
