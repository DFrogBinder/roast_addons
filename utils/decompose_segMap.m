function[segmentation_maps] = decompose_segMap(subject_name,input_file, output_dir)
% DECOMPOSE_SEGMENTATION Loads a NIfTI segmentation file and decomposes it into
% separate tissue maps.
%
%   decompose_segmentation(input_file, output_dir)
%
%   For a 4D NIfTI file (where each volume is a tissue probability map with
%   continuous values between 0 and 1), the function extracts each volume,
%   flips it along the third dimension (to match SPM orientation), and saves it
%   without altering its continuous values.
%
%   For a 3D NIfTI file (assumed to be a label map), the function creates a
%   binary mask for each unique label (0 and 1) and flips each mask along the
%   third dimension.
%
%   Example:
%       decompose_segmentation('segmentation.nii', 'output_masks');

    % Create the output directory if it does not exist.
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    % Load the NIfTI segmentation file.
    nii = load_nii(input_file);
    data = nii.img;
    segmentation_maps = [];

    % Check the dimensionality of the data.
    if ndims(data) == 4
        % 4D case: Assume each 3D volume is a tissue probability map.
        numTissues = size(data, 4);
        fprintf('Detected 4D segmentation with %d tissue probability maps.\n', numTissues);
        for t = 1:numTissues
            % Extract the t-th tissue probability map.
            tissueMap = data(:, :, :, t);
            % Flip along the third dimension to match SPM orientation.
            tissueMap = flip(tissueMap, 3);
            % Copy the original NIfTI structure and update the image data.
            nii_tissue = nii;
            nii_tissue.img = tissueMap;
            % Save the probability map preserving its continuous values.
            output_filename = fullfile(output_dir, sprintf('c%d-11_T1w_ras_1mm_T1andT2.nii',subject_name));
            save_nii(nii_tissue, output_filename);
            fprintf('Saved tissue probability map %d to %s\n', t, output_filename);
        end
    else
        % 3D case: Assume a label map where each voxel has a discrete label.
        tissue_labels = unique(data);
        fprintf('Detected 3D segmentation with tissue labels: %s\n', mat2str(tissue_labels));
        for i = 1:length(tissue_labels)
            label = tissue_labels(i);
            % Create a binary mask: voxels equal to the label become 1, otherwise 0.
            mask = (data == label);
            % Flip the mask along the third dimension.
            mask = flip(mask, 3);
            % Copy the original NIfTI structure and update the image data.
            nii_mask = nii;
            % Convert the binary mask to uint8 (binary images are usually stored as uint8).
            nii_mask.img = uint8(~mask);
            segmentation_maps{end+1} = nii_mask;
            output_filename = fullfile(output_dir, sprintf('c%d%s_T1w_ras_1mm_padded50_T1andT2.nii',label,subject_name));
            save_nii(nii_mask, output_filename);
            fprintf('Saved tissue label %d mask to %s\n', label, output_filename);
        end
    end
end
