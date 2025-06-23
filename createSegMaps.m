close all
clear all

% Define directories.
ti_dir = '/home/boyan/sandbox/Jake_Data/ti_dataset';
segmentation_dir = '/home/boyan/sandbox/Jake_Data/SegMaps';
failed_ids = {};
datasetdir = dir(ti_dir);

% ------------------------------------------------------------
% Identify valid datasets (exclude very short names and Excel files)
% ------------------------------------------------------------
validIdx = [];
for id = 1:length(datasetdir)
    fileName = datasetdir(id).name;
    file_extension = split(fileName, '.');  % split the filename
    if length(fileName) >= 3 && ~strcmp(file_extension(1), 'xlsx')
        validIdx(end+1) = id;  %#ok<AGROW>
    end
end
numValid = length(validIdx);

% Create a fancy waitbar.
hWaitBar = waitbar(0, sprintf('Processing 0 of %d datasets...', numValid), 'Name', 'Progress');

% Process each valid dataset.
for progressCount = 1:numValid
    id = validIdx(progressCount);
    close all
    disp('------------------------------------------------')
    fprintf('Processing ID: %s \n', datasetdir(id).name)
    disp('------------------------------------------------')

    % Construct file names and paths.
    mriFileName = datasetdir(id).name + "_T1w.nii";
    mriFilePath = fullfile(ti_dir, datasetdir(id).name, "anat", mriFileName);

    segFileName = datasetdir(id).name + ".nii";
    segFilePath = fullfile(segmentation_dir, segFileName);
    
    if exist(segFilePath,'file')==2 && exist(mriFilePath,'file')==2

        % Check if subject has already been processed 
        if exist(fullfile("Workbench",datasetdir(id).name+"_Video.avi"),'file')==2
            waitbar(progressCount/numValid, hWaitBar, sprintf('Processing %d of %d datasets...', progressCount, numValid));
            continue
        end

        % Process the data (call your overlay function).
        overlay_seg_maps(segFilePath, mriFilePath, datasetdir(id).name)
        
        % Update the waitbar with progress information.
        waitbar(progressCount/numValid, hWaitBar, sprintf('Processing %d of %d datasets...', progressCount, numValid));
        
        % Optionally, you can also update the console (using fprintf) if desired.
        fprintf('Completed %d/%d\n', progressCount, datasetdir(id).name);
    else
        fprintf('Failed %d/%d\n', progressCount, numValid);
        failed_ids{end+1} = datasetdir(id).name;
        waitbar(progressCount/numValid, hWaitBar, sprintf('Processing %d of %d datasets...', progressCount, numValid));
    end
end

% Clean up the waitbar.
close(hWaitBar);
fprintf('Failed Segmentation IDs:')
disp(failed_ids)