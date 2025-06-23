function segMap2vid_parallel()
    %% Visualise the segmentation map of each scan and save as a video (parallelized)
    close all;
    clear all;
    
    % Define base directory and change directory
    baseDir = '/home/boyan/sandbox/Jake_Data/ti_dataset/';
    cd(baseDir)
    subjFolders = dir;
    N = length(subjFolders);
    
    % Create a waitbar on the client (main) thread
    wb = waitbar(0, 'Processing...');
    
    % Create a DataQueue to receive progress updates from workers
    dq = parallel.pool.DataQueue;
    
    % Initialize a progress counter (will be updated in the nested function)
    progress = 0;
    
    % Set up the callback to update the waitbar every time a worker sends a signal
    afterEach(dq, @updateWaitbar);
    
    % Process folders in parallel
    parfor folder = 1:N
        % Only process valid folders (name length > 2)
        if length(subjFolders(folder).name) > 2
            % Find the segmentation map file in the 'anat' folder
            fileList = dir(fullfile(baseDir, subjFolders(folder).name, 'anat'));
            segMapName = '';
            for file = 1:length(fileList)
                tmp = fileList(file).name;
                if length(tmp) > 10 && strcmp(tmp(end-9:end), '_masks.nii')
                    segMapName = tmp;
                    break;
                end
            end
            if isempty(segMapName)
                % If no valid file is found, signal progress and continue
                send(dq, 1);
                continue;
            end
            
            % Load the segmentation map
            segMapPath = fullfile(baseDir, subjFolders(folder).name, 'anat', segMapName);
            segMap = niftiread(segMapPath);
            subjName = subjFolders(folder).name;
            
            % Create a video writer for the subject
            writerObj = VideoWriter(fullfile('/home/boyan/sandbox/Jake_roast/Workbench/', subjName), 'Motion JPEG 2000');
            open(writerObj);
            
            % Create an invisible figure for plotting frames
            fig = figure('visible', 'off');
            for i = 1:size(segMap, 2)
                imagesc(rot90(squeeze(segMap(:, i, :))));
                title(sprintf("Subjects: %s", subjName));
                hcolor = colorbar;  % use a unique variable name to avoid conflict with waitbar handle
                ylabel(hcolor, 'Magnitude V/m')
                drawnow;  % ensure the figure updates
                frame = getframe(fig);
                writeVideo(writerObj, frame);
            end
            close(writerObj);
            close(fig);
        end
        % Signal that one folder has been processed
        send(dq, 1);
    end
    
    % Close the waitbar after all iterations are done
    close(wb);
    
    %% Nested function to update the waitbar
    function updateWaitbar(~)
        progress = progress + 1;
        waitbar(progress/N, wb);
    end
end
