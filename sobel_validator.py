import cv2
import numpy as np
import subprocess
import matplotlib.pyplot as plt

# --- CONFIGURATION ---
IMAGE_PATH = 'test_image.png'
IMAGE_SIZE = (128, 128) # Must match IMAGE_WIDTH and IMAGE_HEIGHT in Verilog testbench
MEM_FILE_OUT = 'input_pixels.mem'
SIM_OUTPUT_FILE = 'output_edges.txt'
VERILOG_TOP = 'sobel_testbench.v'
VERILOG_MODULES = [
    'image_buffer.v',
    'sobel_core.v',
    'edge_detection_top.v'
]

def preprocess_image(image_path, size):
    """Reads and resizes an image, converts to grayscale, and saves to a .mem file."""
    try:
        img = cv2.imread(image_path)
        if img is None:
            print(f"Error: Image not found at {image_path}")
            return None, None
        
        # Resize and convert to grayscale
        resized_img = cv2.resize(img, size, interpolation=cv2.INTER_AREA)
        gray_img = cv2.cvtColor(resized_img, cv2.COLOR_BGR2GRAY)

        # Save pixel data to .mem file (hex format)
        with open(MEM_FILE_OUT, 'w') as f:
            for row in gray_img:
                for pixel in row:
                    f.write(f'{pixel:02x}\n')
        
        print(f"Successfully preprocessed image and saved to {MEM_FILE_OUT}")
        return gray_img, resized_img
    except Exception as e:
        print(f"An error occurred during image preprocessing: {e}")
        return None, None

def run_verilog_simulation():
    """Compiles and runs the Verilog simulation using Icarus Verilog."""
    print("Running Verilog simulation...")
    command = ['iverilog', '-o', 'sobel_sim', VERILOG_TOP] + VERILOG_MODULES
    
    try:
        subprocess.run(command, check=True, capture_output=True, text=True)
        print("Compilation successful.")
        
        subprocess.run(['vvp', 'sobel_sim'], check=True, capture_output=True, text=True)
        print("Simulation successful.")
    except subprocess.CalledProcessError as e:
        print("An error occurred during simulation.")
        print("Stdout:", e.stdout)
        print("Stderr:", e.stderr)
        return False
    except FileNotFoundError:
        print("Error: Icarus Verilog (iverilog) not found. Please install it.")
        return False
        
    return True

def postprocess_output(size):
    """Reads the simulation output, reconstructs the image, and validates it."""
    try:
        with open(SIM_OUTPUT_FILE, 'r') as f:
            output_pixels = [int(line.strip(), 16) for line in f]
        
        # Reshape the 1D list of pixels into a 2D image array
        output_array = np.array(output_pixels, dtype=np.uint8)
        
        # The first few pixels of output are not valid due to the pipeline
        # We need to reshape the data, leaving out the initial padding
        verilog_img = np.zeros(size, dtype=np.uint8)
        # The number of invalid pixels is 2 rows + 2 pixels per row
        invalid_pixels = 2 * size[0] + 2
        valid_pixels = output_array[invalid_pixels:]
        
        # Pad the output image with black borders to match the original size
        verilog_img[2:size[0], 2:size[1]] = valid_pixels.reshape((size[0]-2, size[1]-2))

        return verilog_img
    except Exception as e:
        print(f"An error occurred during output processing: {e}")
        return None

def calculate_metrics(img1, img2):
    """Calculates Mean Squared Error (MSE) and Peak Signal-to-Noise Ratio (PSNR)."""
    h, w = img1.shape
    diff = cv2.absdiff(img1.astype(float), img2.astype(float))
    mse = np.sum(diff**2) / (h * w)
    psnr = 10 * np.log10((255.0**2) / mse) if mse > 0 else float('inf')
    return mse, psnr

def main():
    """Main function to orchestrate the entire workflow."""
    original_img, color_img = preprocess_image(IMAGE_PATH, IMAGE_SIZE)
    if original_img is None:
        return

    if not run_verilog_simulation():
        return
    
    verilog_output = postprocess_output(IMAGE_SIZE)
    if verilog_output is None:
        return

    # Calculate ground truth with OpenCV's Sobel
    # We use a 3x3 kernel size.
    sobel_x = cv2.Sobel(original_img, cv2.CV_64F, 1, 0, ksize=3)
    sobel_y = cv2.Sobel(original_img, cv2.CV_64F, 0, 1, ksize=3)
    
    # Calculate magnitude: sqrt(sobel_x**2 + sobel_y**2)
    # The verilog design uses |Gx| + |Gy|
    # For a fair comparison, we will also use the Manhattan distance
    opencv_sobel = cv2.add(cv2.convertScaleAbs(sobel_x), cv2.convertScaleAbs(sobel_y))
    
    # Compare the two images
    mse, psnr = calculate_metrics(verilog_output, opencv_sobel)
    print(f"\nValidation Complete:")
    print(f"Mean Squared Error (MSE): {mse:.2f}")
    print(f"Peak Signal-to-Noise Ratio (PSNR): {psnr:.2f} dB")
    print(f"A low MSE indicates high similarity between the Verilog and OpenCV outputs.")
    
    # Display results
    fig, axs = plt.subplots(1, 3, figsize=(15, 5))
    axs[0].imshow(color_img, cmap='gray')
    axs[0].set_title('1. Original Image')
    axs[0].axis('off')
    
    axs[1].imshow(verilog_output, cmap='gray')
    axs[1].set_title('2. Verilog Output')
    axs[1].axis('off')

    axs[2].imshow(opencv_sobel, cmap='gray')
    axs[2].set_title('3. OpenCV Reference')
    axs[2].axis('off')
    
    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    main()
