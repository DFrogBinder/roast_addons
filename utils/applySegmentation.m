function applySegmentation(t1FilePath, segMap)
% APPLYSEGMENTATION Applies a binary segmentation map to a T1w MRI image.
%
%   applySegmentation(t1FilePath, segMapPath) loads the T1w MRI image from
%   t1FilePath and the binary segmentation map from segMapPath, applies the
%   segmentation (by elementwise multiplication), and writes the masked image
%   as a new NIfTI file.
%
%   Example:
%       applySegmentation('T1w.nii', 'segmentation.nii');
%
%   Note:
%       - The segmentation map should be a binary mask (0's and 1's).
%       - Both NIfTI files must have the same dimensions.
%

    % Load the T1w MRI image.
    niiT1 = load_nii(t1FilePath);
    imgT1 = niiT1.img;
    
    % Load the segmentation map.
    segMap = segMap.img;
    
    % Check that the dimensions of the T1 image and segmentation map match.
    if ~isequal(size(imgT1), size(segMap))
        disp(['Size of MRI Image: ',string(size(imgT1))])
        disp(['Size of Segmentation Map: ',string(size(segMap))])
        error('Dimension mismatch: The T1w image and the segmentation map must have the same dimensions.');
    end
    
    % Apply the segmentation mask to the T1 image.
    maskedImg = imgT1 .* segMap;
    
    % Create a new NIfTI structure using the T1 image header.
    niiMasked = niiT1;
    niiMasked.img = maskedImg;
    
    % Construct an output file name by appending '_masked' to the T1 file name.
    [filepath, name, ext] = fileparts(t1FilePath);
    outputFile = fullfile(filepath, [name, '_masked', ext]);
    
    % Save the masked image.
    save_nii(niiMasked, outputFile);
    fprintf('Masked image saved to: %s\n', outputFile);
end
