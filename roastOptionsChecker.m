%% Check roast options in sim 8 as some sims are different to others


clear all;

subjects = dir('/shared/arvaneh_group/Shared/stimsim/CleanedSims/8/');
subjElecCat = zeros(600,2);
i = 0;
for subj = 1:length(subjects)   
    subjName = subjects(subj).name;
    if length(subjName) > 2
        subjDir = strcat('/shared/arvaneh_group/Shared/stimsim/CleanedSims/8/', subjName, '/anat/');
        files = dir(subjDir);
        
        for file = 1:length(files)
            fileName = files(file).name;
            if length(fileName) > 16
                if strcmp(fileName(end-15:end), 'roastOptions.mat')
                    i = i + 1;
                    fprintf("Found file %s for subj %s \n", fileName, subjName);
                    roastOpt = load(strcat(subjDir, fileName));
                    
                    subjElecCat(i, 1) =  str2double(subjName(7:end));
                    
                    if strcmp(roastOpt.opt.configTxt, 'P6 (-0.25 mA), P10 (-0.25 mA), PO4 (-0.25 mA), PO8 (1 mA), O10 (-0.25 mA)')
                       subjElecCat(i, 2) = 1;
                    else
                        roastOpt.opt.configTxt
                        subjElecCat(i, 2) = 2;
                    end
                end
            end
        end
    end
end

%% Work out how many subjects need a full resim
idx_1 = find(subjElecCat(:, 2) == 1);
idx_2 = find(subjElecCat(:, 2) == 2);

subjects_with_1 = subjElecCat(idx_1, 1);
subjects_with_2 = subjElecCat(idx_2, 1);

subjects_only_2 = setdiff(subjects_with_2, subjects_with_1);
    