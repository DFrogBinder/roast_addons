%% Visualise the segmentation map of each scan and save as a video
close all;
clear all;
% baseDir = '/shared/arvaneh_group/Shared/stimsim/mridata/SegmentedMRIs/';

pool1 = parpool('local', 4);

baseDir = '/home/boyan/sandbox/Jake_Data/SegMaps';
cd(baseDir)

subjFolders = dir;
parfor folder = 1:length(subjFolders)
    if length(subjFolders(folder).name) > 2
        tic;
        
        fileList = dir(strcat(baseDir, subjFolders(folder).name));
        
        for file = 1:length(fileList)
            tmp = fileList(file).name;
            if length(tmp) > 10
                if strcmp(tmp(end-9:end), '_masks.nii')
                    segMapName = tmp;
                    break
                end
            end
        end
        % Load segmentation map
        segMap = niftiread(strcat(baseDir, subjFolders(folder).name, '/anat/', segMapName));
        %segMap = segMap.dat;
        subjName = subjFolders(folder).name;


        writerObj = VideoWriter(strcat('/home/boyan/sandbox/roast/Outputs', subjName), 'Motion JPEG 2000');
        open(writerObj);
        
        fig = figure('visible', 'off');
        %fig.Position = [100 100 450 550];
        for i = 1:size(segMap, 2)
            plotHandle = imagesc(rot90(squeeze(segMap(:, i, :)))); 
            title(sprintf("Subjects: %s\n", subjName));
            h = colorbar;
            ylabel(h, 'Magnitude V/m')
            capturedFrames(i) = getframe(fig);
            writeVideo(writerObj, capturedFrames(i));
        end
        close(writerObj);
        %movieFig = figure();
        %movie(movieFig, capturedFrames, 100, 6);
        close all;
        fprintf("Time to load and plot %d\n", round(toc))
    end
end