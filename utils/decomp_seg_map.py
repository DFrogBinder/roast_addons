import os
import argparse
import numpy as np
import nibabel as nib

def decompose_segmentation(input_file, output_dir):
    # Load the segmentation NIfTI file
    nii = nib.load(input_file)
    data = nii.get_fdata()
    
    # Identify unique tissue types (assumed to be represented by different integer labels)
    tissue_labels = np.unique(data)
    print("Found tissue labels:", tissue_labels)
    
    # Create the output directory if it doesn't exist
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    # Loop over each tissue label and save a binary mask for that tissue
    for label in tissue_labels:
        # Create a binary mask: tissue present=1, else=0
        mask = (data == label).astype(np.uint8)
        
        # Create a new NIfTI image using the same affine and header
        tissue_img = nib.Nifti1Image(mask, affine=nii.affine, header=nii.header)
        
        # Define the output filename; here we compress using .nii.gz
        output_file = os.path.join(output_dir, f"tissue_{int(label)}.nii.gz")
        nib.save(tissue_img, output_file)
        print(f"Saved tissue label {label} to {output_file}")

def main():
    parser = argparse.ArgumentParser(description="Decompose a .nii segmentation map into separate tissue files")
    parser.add_argument("input_file", help="Path to the input segmentation .nii or .nii.gz file")
    parser.add_argument("output_dir", help="Directory where the tissue files will be saved")
    args = parser.parse_args()
    
    decompose_segmentation(args.input_file, args.output_dir)

if __name__ == '__main__':
    main()

