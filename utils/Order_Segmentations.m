% Define the directory containing .nii files
input_dir = '/home/boyan/sandbox/tmp/'; % Change this to your actual directory

% Get a list of all .nii files in the directory
nii_files = dir(fullfile(input_dir, '*.nii'));

% Loop through each .nii file
for i = 1:length(nii_files)
    try
        % Extract file name without extension
        nii_file = fullfile(input_dir, nii_files(i).name);
        [~, name, ~] = fileparts(nii_files(i).name);
        
        % Create a dedicated folder for this file
        output_dir = fullfile(input_dir, name);
        if ~exist(output_dir, 'dir')
            mkdir(output_dir);
        end
        
        % Move the .nii file into its corresponding folder
        movefile(nii_file, output_dir);
        
        fprintf('Moved %s to %s\n', nii_files(i).name, output_dir);
    catch ME
        warning('Failed to move %s: %s', nii_files(i).name, ME.message);
    end
end

fprintf('All files processed.\n');
