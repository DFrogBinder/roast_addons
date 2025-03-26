%% Move the segmentation maps to relevant folders
clear all;
cd('/shared/arvaneh_group/Shared/stimsim/Set4')

segMaps = dir;

for i = 1:length(segMaps)
    if length(segMaps(i).name) > 2
       
       fileName = segMaps(i).name;
       subjName = fileName(1:12);
       
       
       for simNum = 1:10
            sourcePath = strcat('/shared/arvaneh_group/Shared/stimsim/Set4/', fileName);
            destinationPath = strcat('/shared/arvaneh_group/Shared/stimsim/CleanedSims/', string(simNum), '/', subjName, '/anat/'); %, rawMRIT1);
            fprintf("Moving subj %s sim number %d \n", subjName, simNum);
            copyfile(sourcePath, destinationPath);
            fprintf("--- Moved --- \n");
       end
       
    end
end