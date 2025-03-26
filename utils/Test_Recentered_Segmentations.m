% Define input and output directories
input_dir = '/home/boyan/sandbox/tmp';  % Change this to your .nii files directory

% Get all subdirectories
subdirs = dir(input_dir);
subdirs = subdirs([subdirs.isdir]); % Keep only directories
subdirs = subdirs(~ismember({subdirs.name}, {'.', '..'})); % Remove '.' and '..'

% Convert to a struct array to avoid parfor issues
subdirs = struct2cell(subdirs)';
subdirs = subdirs(:,1); % Extract only the folder names

% Initialize a cell array to store failed simulations
failed_simulations = strings(length(subdirs), 1);

% Start parallel pool if not already running
if isempty(gcp('nocreate'))
    parpool; % Start parallel pool with default workers
end

% Create a DataQueue for progress updates
progressQueue = parallel.pool.DataQueue;
numTotal = length(subdirs);
progress = 0;

% Display initial progress bar
fprintf('Progress: [');
barLength = 40; % Length of the progress bar
fprintf(repmat(' ', 1, barLength));
fprintf('] 0%%\n');

% Function to update progress bar dynamically
function updateProgress()
    progress = progress + 1;
    percent_complete = progress / numTotal;
    num_hashes = round(percent_complete * barLength);

    % Print progress bar
    fprintf('\rProgress: [%s%s] %2d%%', ...
        repmat('#', 1, num_hashes), repmat(' ', 1, barLength - num_hashes), round(percent_complete * 100));
end

% Attach the function to the queue
afterEach(progressQueue, @updateProgress);

% Parallel loop through each subdirectory
parfor i = 1:length(subdirs)
    close all; % Close all open figures in each worker

    try
        % Get the subdirectory name
        subdir_name = subdirs{i};
        subdir_path = fullfile(input_dir, subdir_name);

        % Find the .nii file in the subdirectory
        nii_files = dir(fullfile(subdir_path, '*.nii'));
        
        % If no .nii file is found, skip this subdirectory
        if isempty(nii_files)
            warning('No .nii file found in %s. Skipping...', subdir_path);
            continue;
        end
        
        % Use the first (and only) .nii file in the subdirectory
        nii_file = fullfile(subdir_path, nii_files(1).name);
        
        % Run ROAST
        fprintf('Running ROAST for %s on worker %d...\n', nii_files(1).name, getCurrentTask().ID);
        roast(nii_file);
        
        fprintf('Successfully completed: %s\n', nii_files(1).name);
        
    catch ME
        % If an error occurs, log it safely
        warning('Failed to process: %s\nError: %s', nii_files(1).name, ME.message);
        failed_simulations(i) = fullfile(subdir_name, nii_files(1).name,ME.message);
    end

    % Update progress bar
    send(progressQueue, 1);
end

% Remove empty entries from failed simulations
failed_simulations = failed_simulations(failed_simulations ~= "");

% Save failed simulations to a log file
log_file = fullfile(input_dir, 'failed_simulations.txt');
fid = fopen(log_file, 'w');
if fid ~= -1
    for i = 1:length(failed_simulations)
        fprintf(fid, '%s\n', failed_simulations(i));
    end
    fclose(fid);
end

fprintf('\nProcessing complete. Failed simulations logged in %s\n', log_file);
