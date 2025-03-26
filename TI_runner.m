%% TI Stimulation Simulation Experiment
% This script runs two simulations per subject (TI_right and TI_left) and then
% performs a custom TI calculation after both simulations are complete.
% The structure is designed for future multithreading (e.g., using parfor).

close all;
clear all;

% Define the parent directory where subject subdirectories are stored
parentDir = '/home/boyan/sandbox/Jake_Data/Example_data/';

% List subject directories (assuming they start with 'sub-CC')
subjects = dir(fullfile(parentDir, 'sub-CC*'));
numSubj = length(subjects);

% Loop through each subject (this loop can later be replaced by a parfor)
for s = 1:numSubj
    subjFolder = subjects(s).name;
    subjDir = fullfile(parentDir, subjFolder);
    anatDir = fullfile(subjDir, 'anat');
    
    % Display current subject processing status
    fprintf('\n----------------------- Processing %s -----------------------\n', subjFolder);
    
    %%% Step 1: File Management & Preprocessing
    % (Reuse code from your original script for cleaning files, unzipping,
    %  adding zero padding, etc.)
    %
    % For brevity, we assume that the following block of code performs:
    %   - Listing files in anatDir
    %   - Deleting extraneous files while keeping the original MRI and segmap
    %   - Unzipping T1 and T2 scans if not already unzipped
    %   - Performing zero padding on the segmentation map
    %
    % You may encapsulate these tasks in separate functions for clarity.
    
    folder_contents = dir(anatDir);
    files = {folder_contents.name};
    
    % (Clean-up: delete unnecessary files)
    no_files = numel(files);
    for f = 1:no_files
        fileName = files{f};
        % Only process files with long names (as in original logic)
        if length(fileName) > 11
            % Keep files ending with '.nii.gz' or '_masks.nii'
            if ~(endsWith(fileName, '.nii.gz') || endsWith(fileName, '_masks.nii'))
                fprintf('Deleted %s\n', fileName);
                delete(fullfile(anatDir, fileName));
            elseif endsWith(fileName, '_masks.nii')
                % If filename is unusually long, delete it (unless it is our desired segmap)
                if length(fileName) > 50
                    fprintf('Deleted %s\n', fileName);
                    delete(fullfile(anatDir, fileName));
                else
                    segMapFileName = fileName;
                end
            end
        elseif length(fileName) > 2
            fprintf('Deleted %s\n', fileName);
            delete(fullfile(anatDir, fileName));
        end
    end
    
    % Unzip T1 and T2 files if necessary
    % (Assume file names follow the pattern: [subjFolder '_T1w.nii.gz'] etc.)
    t1_gz = fullfile(anatDir, [subjFolder '_T1w.nii.gz']);
    t2_gz = fullfile(anatDir, [subjFolder '_T2w.nii.gz']);
    t1_nii = fullfile(anatDir, [subjFolder '_T1w.nii']);
    t2_nii = fullfile(anatDir, [subjFolder '_T2w.nii']);
    
    if ~exist(t1_nii, 'file') && exist(t1_gz, 'file')
        gunzip(t1_gz, anatDir);
        fprintf('Unzipped T1 for %s\n', subjFolder);
    end
    if ~exist(t2_nii, 'file') && exist(t2_gz, 'file')
        gunzip(t2_gz, anatDir);
        fprintf('Unzipped T2 for %s\n', subjFolder);
    end
    
    % Add zero padding to the segmentation map if needed
    % (Assuming the function zeroPadding exists and takes a file path and a padding value)
    segMapFileDir = fullfile(anatDir, segMapFileName);
    zeroPadding(segMapFileDir, 50);
    
    %%% Step 2: Run the Two Simulations (TI_right and TI_left)
    % Define output marker file names
    completeRight = fullfile(anatDir, 'TI_right_complete.txt');
    completeLeft  = fullfile(anatDir, 'TI_left_complete.txt');
    
    % Define common variables for ROAST call
    stl_model_name = strcat(subjFolder, '_stl');
    mri_directory = anatDir;
    t1_filename = [subjFolder '_T1w.nii'];
    t2_filename = [subjFolder '_T2w.nii'];
    
    % --- Simulation for TI_right (e.g., right electrode pair) ---
    if ~exist(completeRight, 'file')
        try
            fprintf('Starting TI_right simulation for %s\n', subjFolder);
            % Define the montage for the right simulation.
            % (Adjust electrode labels, current intensities, and other parameters as needed.)
            montage_right = {'F4', 1, 'C4', -1};
            
            roast(...
                fullfile(mri_directory, t1_filename), ...
                montage_right, ...
                stl_model_name, ...
                'elecType', {'disc','disc'}, ...
                'elecSize', {[28.21 1], [28.21, 1]}, ...
                'elecOri', 'ap', ...
                'T2', fullfile(mri_directory, t2_filename), ...
                'conductivities', struct('csf', 0.85), ...
                'resampling', 'on', ...
                'zeroPadding', 50);
            
            % Mark TI_right simulation as complete
            parsave(completeRight);
            fprintf('TI_right simulation complete for %s\n', subjFolder);
            close all;
        catch ME
            fprintf('ERROR - TI_right simulation NOT COMPLETE for %s: %s\n', subjFolder, ME.message);
        end
    else
        fprintf('TI_right simulation already complete for %s\n', subjFolder);
    end
    
    % --- Simulation for TI_left (e.g., left electrode pair) ---
    if ~exist(completeLeft, 'file')
        try
            fprintf('Starting TI_left simulation for %s\n', subjFolder);
            % Define the montage for the left simulation.
            % (Adjust electrode labels and parameters as needed.)
            montage_left = {'F3', 1, 'C3', -1};
            
            roast(...
                fullfile(mri_directory, t1_filename), ...
                montage_left, ...
                stl_model_name, ...
                'elecType', {'disc','disc'}, ...
                'elecSize', {[28.21 1], [28.21, 1]}, ...
                'elecOri', 'ap', ...
                'T2', fullfile(mri_directory, t2_filename), ...
                'conductivities', struct('csf', 0.85), ...
                'resampling', 'on', ...
                'zeroPadding', 50);
            
            % Mark TI_left simulation as complete
            parsave(completeLeft);
            fprintf('TI_left simulation complete for %s\n', subjFolder);
            close all;
        catch ME
            fprintf('ERROR - TI_left simulation NOT COMPLETE for %s: %s\n', subjFolder, ME.message);
        end
    else
        fprintf('TI_left simulation already complete for %s\n', subjFolder);
    end
    
    %%% Step 3: Post-Processing: Calculate TI Stimulation Field
    % Only run the TI calculation if both simulations have completed and if not already done.
    tiCalcMarker = fullfile(anatDir, 'TI_calculated.txt');
    if exist(completeRight, 'file') && exist(completeLeft, 'file') && ~exist(tiCalcMarker, 'file')
        try
            fprintf('Running calculate_TI.m for %s\n', subjFolder);
            % Option 1: if calculate_TI.m is written to operate on the current directory:
            % cd(anatDir);
            % calculate_TI;
            %
            % Option 2: if calculate_TI.m accepts a subject directory as input:
            calculate_TI(anatDir);
            
            % Mark TI calculation as complete
            parsave(tiCalcMarker);
            fprintf('TI stimulation field calculation complete for %s\n', subjFolder);
        catch ME
            fprintf('ERROR - TI calculation NOT COMPLETE for %s: %s\n', subjFolder, ME.message);
        end
    elseif exist(tiCalcMarker, 'file')
        fprintf('TI stimulation field already calculated for %s\n', subjFolder);
    else
        fprintf('Waiting on both simulations to complete for %s\n', subjFolder);
    end
end

% If you use a parallel pool later, make sure to delete it outside the loop.
% delete(gcp('nocreate'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function parsave(filePath)
    % parsave: Creates a marker file to indicate completion.
    % This function simply saves an empty .mat file or writes a simple text file.
    fid = fopen(filePath, 'w');
    if fid ~= -1
        fprintf(fid, 'Simulation complete.');
        fclose(fid);
        fprintf('Saved marker file: %s\n', filePath);
    else
        error('Could not create marker file: %s', filePath);
    end
end

function zeroPadding(segMapFile, padVal)
    % zeroPadding: Dummy placeholder for the zero padding function.
    % In your actual code, this should load the segmentation map,
    % add the required zero padding, and write the padded segmap back.
    %
    % For example:
    % segMap = niftiread(segMapFile);
    % ... (add padding) ...
    % niftiwrite(segMap, segMapFile);
    %
    % Here we simply print that padding is applied.
    fprintf('Zero padding applied to %s with pad value %d\n', segMapFile, padVal);
end
