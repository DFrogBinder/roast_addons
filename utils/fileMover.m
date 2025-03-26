%% Copy over the raw MRI files over to the new folders
cd('/shared/arvaneh_group/Shared/stimsim/mridata/SegmentedMRIs');
subjects = dir;
for subj = 1:length(subjects)
    if length(subjects(subj).name) > 5
        cd(strcat('/shared/arvaneh_group/Shared/stimsim/mridata/SegmentedMRIs/', subjects(subj).name, '/anat/'));
        
        subjFiles = dir;
        for file = 1:length(subjFiles)
            if length(subjFiles(file).name) > 10
                tmpFileName = subjFiles(file).name;
                %fprintf("tmpFileName
                
                if strcmp(tmpFileName(end-9:end), 'T2w.nii.gz')
                    rawMRIT2 = tmpFileName;
                end
                
                if strcmp(tmpFileName(end-9:end), 'T1w.nii.gz')
                    rawMRIT1 = tmpFileName;
                end
            end
        end
        %rawMRIT1 =
        %rawMRIT2 =
        
        for simNum = 1:6
            fprintf("Moving subj %s sim number %d \n", subjects(subj).name, simNum);
            sourcePath = strcat('/shared/arvaneh_group/Shared/stimsim/mridata/SegmentedMRIs/', subjects(subj).name, '/anat/', rawMRIT1);
            destinationPath = strcat('/shared/arvaneh_group/Shared/stimsim/CleanedSims/', string(simNum), '/', subjects(subj).name, '/anat/'); %, rawMRIT1);
            copyfile(sourcePath, destinationPath);
            %
            sourcePath = strcat('/shared/arvaneh_group/Shared/stimsim/mridata/SegmentedMRIs/', subjects(subj).name, '/anat/', rawMRIT2);
            destinationPath = strcat('/shared/arvaneh_group/Shared/stimsim/CleanedSims/', string(simNum), '/', subjects(subj).name, '/anat/', rawMRIT2);
            copyfile(sourcePath, destinationPath);
            fprintf("---- Moved ---");
        end
        
        %         mkdir(strcat('/shared/arvaneh_group/Shared/stimsim/CleanedSims/1/',subjects(subj).name, '/anat/'))
        %         mkdir(strcat('/shared/arvaneh_group/Shared/stimsim/CleanedSims/2/',subjects(subj).name, '/anat/'))
        %         mkdir(strcat('/shared/arvaneh_group/Shared/stimsim/CleanedSims/3/',subjects(subj).name, '/anat/'))
        %         mkdir(strcat('/shared/arvaneh_group/Shared/stimsim/CleanedSims/4/',subjects(subj).name, '/anat/'))
        %         mkdir(strcat('/shared/arvaneh_group/Shared/stimsim/CleanedSims/5/',subjects(subj).name, '/anat/'))
        %         mkdir(strcat('/shared/arvaneh_group/Shared/stimsim/CleanedSims/6/',subjects(subj).name, '/anat/'))
        %subjData = dir;
    end
    
    
end