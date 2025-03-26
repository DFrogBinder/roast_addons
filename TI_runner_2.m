%% run_TI_simulations.m
% This script performs TI stimulation experiments for multiple subjects.
% For each subject, it:
%   1. Preprocesses the subject’s MRI and segmentation files (cleanup, unzipping, zero padding).
%   2. Runs two simulations (TI_right and TI_left) with different electrode montages.
%   3. Once both simulations are complete, it runs a custom TI calculation to sum the fields.
%
% Marker files in each subject's "anat" folder track the progress.
% The script is written to be easily parallelized later.

close all;
clear all;

%% Settings
parentDir = '/home/boyan/sandbox/Jake_Data/Example_data/';
subjectPattern = 'sub-CC*';  % Assumes subject folders start with "sub-CC"

% Common simulation parameters
elecType       = {'disc', 'disc'};
elecSize       = {[28.21 1], [28.21 1]};
elecOri        = 'ap';
resamplingFlag = 'on';
csfConductivity= 0.85;
zeroPadValue   = 50;

% Montage configurations (customize electrode labels and currents as needed)
montage_right = {'F4', 1, 'C4', -1};  % Example configuration for TI_right simulation
montage_left  = {'F3', 1, 'C3', -1};   % Example configuration for TI_left simulation

%% List subject directories
subjectDirs = dir(fullfile(parentDir, subjectPattern));
numSubj = length(subjectDirs);

%% Process each subject (replace with parfor for multithreading later)
for i = 1:numSubj
    subjFolder = subjectDirs(i).name;
    subjPath = fullfile(parentDir, subjFolder);
    anatDir  = fullfile(subjPath, 'anat');
    
    fprintf('\n=== Processing Subject: %s ===\n', subjFolder);
    
    %% Step 1: Preprocessing
    % Clean up files in the "anat" folder
    cleanUpFiles(anatDir);
    
    % % Unzip T1 and T2 files if needed (assumes naming convention: [subjFolder '_T1w.nii.gz'])
    % t1_nii = fullfile(anatDir, [subjFolder '_T1w.nii']);
    % t2_nii = fullfile(anatDir, [subjFolder '_T2w.nii']);
    % t1_gz  = fullfile(anatDir, [subjFolder '_T1w.nii.gz']);
    % t2_gz  = fullfile(anatDir, [subjFolder '_T2w.nii.gz']);
    % 
    % if ~exist(t1_nii, 'file') && exist(t1_gz, 'file')
    %     gunzip(t1_gz, anatDir);
    %     fprintf('Unzipped T1 for %s\n', subjFolder);
    % end
    % if ~exist(t2_nii, 'file') && exist(t2_gz, 'file')
    %     gunzip(t2_gz, anatDir);
    %     fprintf('Unzipped T2 for %s\n', subjFolder);
    % end
    
    % Find segmentation map file (assumes filename ends with "_masks.nii")
    segMapFile = findSegMapFile(anatDir);
    if isempty(segMapFile)
        warning('No segmentation map found for %s. Skipping subject.', subjFolder);
        continue;
    end
    segMapPath = fullfile(anatDir, segMapFile);
    
    % Apply zero padding to the segmentation map (dummy function here)
    zeroPadding(segMapPath, zeroPadValue);
    
    %% Step 2: Run TI Simulations
    % Marker file names to track progress
    marker_right = fullfile(anatDir, 'TI_right_complete.txt');
    marker_left  = fullfile(anatDir, 'TI_left_complete.txt');
    marker_TI    = fullfile(anatDir, 'TI_calculated.txt');
    
    stl_model_name = [subjFolder '_stl'];
    
    % Run TI_right simulation (if not already complete)
    if ~exist(marker_right, 'file')
        try
            fprintf('Running TI_right simulation for %s...\n', subjFolder);
            roast( fullfile(anatDir, [subjFolder '_T1w.nii']), ...
                   montage_right, stl_model_name, ...
                   'elecType',       elecType, ...
                   'elecSize',       elecSize, ...
                   'elecOri',        elecOri, ...
                   'T2',             fullfile(anatDir, [subjFolder '_T2w.nii']), ...
                   'conductivities', struct('csf', csfConductivity), ...
                   'resampling',     resamplingFlag, ...
                   'zeroPadding',    zeroPadValue );
            parsave(marker_right);
            fprintf('TI_right simulation complete for %s.\n', subjFolder);
        catch ME
            fprintf('Error during TI_right simulation for %s: %s\n', subjFolder, ME.message);
            continue;
        end
    else
        fprintf('TI_right simulation already complete for %s.\n', subjFolder);
    end
    
    % Run TI_left simulation (if not already complete)
    if ~exist(marker_left, 'file')
        try
            fprintf('Running TI_left simulation for %s...\n', subjFolder);
            roast( fullfile(anatDir, [subjFolder '_T1w.nii']), ...
                   montage_left, stl_model_name, ...
                   'elecType',       elecType, ...
                   'elecSize',       elecSize, ...
                   'elecOri',        elecOri, ...
                   'T2',             fullfile(anatDir, [subjFolder '_T2w.nii']), ...
                   'conductivities', struct('csf', csfConductivity), ...
                   'resampling',     resamplingFlag, ...
                   'zeroPadding',    zeroPadValue );
            parsave(marker_left);
            fprintf('TI_left simulation complete for %s.\n', subjFolder);
        catch ME
            fprintf('Error during TI_left simulation for %s: %s\n', subjFolder, ME.message);
            continue;
        end
    else
        fprintf('TI_left simulation already complete for %s.\n', subjFolder);
    end
    
    %% Step 3: Calculate Combined TI Field
    % Run TI calculation only if both simulations are complete and the calculation hasn't been run
    if exist(marker_right, 'file') && exist(marker_left, 'file') && ~exist(marker_TI, 'file')
        try
            fprintf('Running TI field calculation for %s...\n', subjFolder);
            % Assume calculate_TI takes the anatDir as input and performs the summing operation
            calculate_TI(anatDir);
            parsave(marker_TI);
            fprintf('TI field calculation complete for %s.\n', subjFolder);
        catch ME
            fprintf('Error during TI field calculation for %s: %s\n', subjFolder, ME.message);
        end
    else
        fprintf('TI field calculation already complete or waiting on simulations for %s.\n', subjFolder);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Helper Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function cleanUpFiles(anatDir)
    % Delete all files except for original MRI and segmap
    folder_contents = dir(anatDir);
    files = struct2cell(folder_contents);
    
    no_files = size(files, 2);
    if no_files > 4
        for file_no = 1:no_files % Loop through al files
            file = files(1, file_no);
            file = file{1};
           if length(file)>11 % Only check long filenames
                % Keep original MRI and mask
                if ~strcmp(file(end-6:end), '.nii.gz') &&  ~strcmp(file(end-9:end), '_masks.nii')
                    fprintf("Deleted %s \n", file)
                    delete(fullfile(anatDir, file))
                elseif strcmp(file(end-9:end), '_masks.nii')
                    if length(file) > 50
                        fprintf("Deleted %s \n", file)
                         delete(fullfile(anatDir, file))
                    else
                        segMapFileName = file;
                    end
                end
    
            elseif length(file)> 2
                fprintf("Deleted %s \n", file)
                delete(fullfile(anatDir, file))
            end
        end
    end
end

function segMapFile = findSegMapFile(anatDir)
    % findSegMapFile searches for a file ending with '_masks.nii' in anatDir.
    segMapFile = '';
    files = dir(anatDir);
    for j = 1:length(files)
        if ~files(j).isdir && endsWith(files(j).name, '_masks.nii')
            segMapFile = files(j).name;
            return;
        end
    end
end

% function parsave(filePath)
%     % parsave creates a marker file to indicate that a simulation step is complete.
%     fid = fopen(filePath, 'w');
%     if fid == -1
%         error('Could not create marker file: %s', filePath);
%     end
%     fprintf(fid, 'Done');
%     fclose(fid);
%     fprintf('Created marker file: %s\n', filePath);
% end

function parsave(filePath)
    % robustParsave creates a marker file with additional metadata (timestamp)
    % using a temporary file to ensure atomic write operations.
    tempFile = [filePath, '.tmp'];
    fid = fopen(tempFile, 'w');
    if fid == -1
        error('Could not open temporary file for writing: %s', tempFile);
    end
    timestamp = datetime("now", 'yyyy-mm-dd HH:MM:SS');
    fprintf(fid, 'Status: Done\nTimestamp: %s\n', timestamp);
    fclose(fid);
    % Atomically move temporary file to final marker file
    status = movefile(tempFile, filePath, 'f');
    if ~status
        error('Could not move temporary marker file to final location: %s', filePath);
    else
        fprintf('Created robust marker file: %s\n', filePath);
    end
end

function zeroPadding(segMapFile, padVal)
    % zeroPadding applies zero padding to the segmentation map.
    % Replace the contents of this function with your actual padding code.
    fprintf('Applying zero padding to %s with pad value %d.\n', segMapFile, padVal);
    % Example (commented):
    % segMap = niftiread(segMapFile);
    % paddedSegMap = padarray(segMap, [padVal padVal padVal], 0, 'both');
    % niftiwrite(paddedSegMap, segMapFile);
end
