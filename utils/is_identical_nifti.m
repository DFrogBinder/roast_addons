function is_identical_nifti(file1, file2)
%COMPARE_NIFTI Compare two NIfTI files for identical segmentation masks.
%   compare_nifti(file1, file2) reads the NIfTI files specified by file1
%   and file2, compares their voxel data arrays and header metadata, and
%   prints the results.
%
%   Example:
%       compare_nifti('segmentation1.nii', 'segmentation2.nii')

    % Read the image data from the NIfTI files
    data1 = niftiread(file1);
    data2 = niftiread(file2);

    % Retrieve header (metadata) information
    info1 = niftiinfo(file1);
    info2 = niftiinfo(file2);

    % Check if the dimensions of the two images match
    if ~isequal(size(data1), size(data2))
        fprintf('The segmentation masks have different dimensions.\n');
    else
        % Compare the data arrays
        if isequal(data1, data2)
            fprintf('The segmentation masks are identical.\n');
        else
            fprintf('The segmentation masks differ.\n');
        end
    end

    % Optionally, compare header information
    if isequal(info1, info2)
        fprintf('The header information is identical.\n');
    else
        fprintf('The header information differs.\n');
    end

end
