%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% correctOrientation
%
% This function takes a reference volume (the MRI), its NIfTI info, and a target
% volume (the segmentation map) with its info. It computes the relative transformation
% required to map the target volume into the reference space using the header-affine.
% The function then applies this transform with nearest-neighbor interpolation.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function correctedVolume = correctOrientation(mriFile, segFile)
    % Ensure input filenames are character arrays.
    mriFile = char(mriFile);
    segFile = char(segFile);
    
    % Check for SPM's spm_reslice function.
    if exist('spm_reslice', 'file') ~= 2
       error('SPM functions not found. Please add SPM to your MATLAB path.');
    end
    
    % Create a cell array of file names.
    files = {mriFile, segFile};
    
    % Convert the cell array to an SPM volume structure.
    P = spm_vol(files);
    
    % Set options for spm_reslice:
    %   - mean: false (do not create mean image)
    %   - which: 1 (write resliced images)
    %   - interp: 0 (use nearest neighbor interpolation for label images)
    %   - wrap: [0 0 0]
    %   - mask: 0
    opts.mean   = false;
    opts.which  = 1;
    opts.interp = 0;
    opts.wrap   = [0 0 0];
    opts.mask   = 0;
    
    % Call spm_reslice using the SPM volume structure.
    spm_reslice(P, opts);
    
    % Construct the filename for the resliced segmentation image (prefixed with 'r').
    [p, n, ext] = fileparts(segFile);
    reorientedFile = fullfile(p, ['r', n, ext]);
    
    % Load the reoriented segmentation volume.
    correctedVolume = niftiread(reorientedFile);
    
    % Optionally, you may delete the temporary resliced file:
    % delete(reorientedFile);
end