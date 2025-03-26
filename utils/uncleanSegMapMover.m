%% Move the non-cleaned up segmentaiton maps to the relevant folder to speed up the simulation
clear all;
cd('/shared/arvaneh_group/Shared/stimsim/CleanedSims/1/')
folder = dir;

% Loop through folders and find relevant file
% If relevant file exists copy and paste to relevant folder

for subj = 1:length(folder)
    if length(folder(subj).name) > 2 % Ignore empty files
        tmpSubjName = folder(subj).name;
        cd(strcat('/shared/arvaneh_group/Shared/stimsim/CleanedSims/1/', tmpSubjName, '/anat/'));
        subjFiles = dir;
        fileToMove = 0;
        for file = 1:length(subjFiles)
            tmpFileName = subjFiles(file).name;
            if length(tmpFileName) > 10
                % if strcmp(tmpFileName(1:5), 'c1sub')
                if strcmp(tmpFileName(end-8:end), '_seg8.mat')
                    fileToMove = tmpFileName;
                end
            end
        end
        
        if fileToMove ~= 0
            fileSource = strcat('/shared/arvaneh_group/Shared/stimsim/CleanedSims/1/', tmpSubjName, '/anat/', fileToMove);
            fileDestination = strcat('/shared/arvaneh_group/Shared/stimsim/CleanedSims/10/', tmpSubjName, '/anat/', fileToMove);
            copyfile(fileSource, fileDestination);
            fprintf("File for %s moved.\n", tmpSubjName);
        else 
            fprintf("Subj %s has no file.\n", tmpSubjName);
        end
    end
end
        