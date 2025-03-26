%% ROAST simulation of CamCAN dataset
close all;
clear all;


while true
    % tmpdata = readtable('sims2repeat.xlsx');
    

    % numComplete = 0;
    % numSubj = height(tmpdata);
    % for subjects = 1:numSubj
    %     tmpSubjID = tmpdata.Var2(subjects);
    %     tmpSubjSimNum =  tmpdata.Var1(subjects);
    %     subjFiles = dir(strcat('/home/boyan/sandbox/Jake_Data/Example_data/', string(tmpSubjSimNum), '/', 'sub-CC',string(tmpSubjID), '/anat/'));
    %     for tmpFiles = 1:length(subjFiles)
    %         if length(subjFiles(tmpFiles).name) > 5
    %             tmpfileName = subjFiles(tmpFiles).name;
    %             if strcmp(tmpfileName(end-3:end), '.txt')
    %                 numComplete = numComplete + 1;
    %             end
    %         end
    %     end
    % end

    subjects = dir('/home/boyan/sandbox/Jake_Data/Example_data/');
    numComplete = 0;
    numSubj = length(subjects);

    if numComplete == numSubj % All sims complete
        fprintf(" \n---- ALL SIMS COMPLETE --- \n")
        break;
    else
        fprintf("%d sims complete, continuing...", numComplete);
    end

    
    for p = 1:length(subjects)
    % parfor p = 1:numSubj  % loop through participants
        data = readtable('sims2repeat_2.xlsx');
        simNum = data.Var1(p);
        subjID = data.Var2(p);
        parentDir =  strcat('/home/boyan/sandbox/Jake_Data/Example_data');
        % Sim complete in a previous loop, skip
        subjFiles = dir(strcat((parentDir), '/', 'sub-CC', string(subjID), '/anat/'));
        for tmpfiles = 1:length(subjFiles)
            if length(subjFiles(tmpfiles).name) > 11
                tmpfileName = subjFiles(tmpfiles).name;
                if strcmp(tmpfileName(end-3:end), '.txt')
                    simComplete = 1;
                end
            end
        end

    simComplete=0;
        if simComplete == 1
            fprintf("Subj in position %d is complete, moving on to the next. \n", p);
            continue;
        end

        folder = strcat('sub-CC', string(subjID));

        fprintf("----------------------- Checking %s ----------------------", folder);
        
        folder_contents = dir(strcat((parentDir), '/', folder, '/', 'anat'));
        files = struct2cell(folder_contents);

        % Delete all files except for original MRI and segmap
        no_files = size(files, 2);
        if no_files > 4
            for file_no = 1:no_files % Loop through al files
                file = files(1, file_no);
                file = file{1};
               if length(file)>11 % Only check long filenames
                    % Keep original MRI and mask
                    if ~strcmp(file(end-6:end), '.nii.gz') &&  ~strcmp(file(end-9:end), '_masks.nii')
                        fprintf("Deleted %s \n", file)
                        delete(strcat((parentDir), '/', folder, '/', 'anat', '/', file))
                    elseif strcmp(file(end-9:end), '_masks.nii')
                        if length(file) > 50
                            fprintf("Deleted %s \n", file)
                             delete(strcat((parentDir), '/', folder, '/', 'anat', '/', file))
                        else
                            segMapFileName = file;
                        end
                    end

                elseif length(file)> 2
                    fprintf("Deleted %s \n", file)
                    delete(strcat((parentDir), '/', folder, '/', 'anat', '/', file))
                end
            end
        end

        % Add zero padding to the seg map so it can be used
        %segMapZeroPadding(strcat((parentDir), '\', folder, '\', 'anat', '\'), segMapFileName);

        segMapFileDir = char(strcat((parentDir), '/', folder, '/', 'anat', '/', segMapFileName));
 
        zeroPadding(segMapFileDir, 50); % Add zero padding to the cleaned segmap

        % Rename the segmap so ROAST recognises it and doesn't repeat
        % segmentation (without cleaning)
        source = strcat((parentDir), '/', folder, '/', 'anat', '/', folder, '_T1w_ras_1mm_T1andT2_masks_padded50.nii');
        destination =  strcat((parentDir), '/', folder, '/', 'anat', '/', folder, '_T1w_ras_1mm_padded50_T1andT2_masks.nii');
        if exist(source,"file")
            [~, sname, sext] = fileparts(source);
            sfilename = strjoin([sname, sext],'');

            [~, dname, dext] = fileparts(destination);
            dfilename = strjoin([dname, dext],'');
            fprintf("\n Renaming: \n %s ==> %s \n", sfilename, dfilename)
            movefile(source, destination)
        end
        % If results don't exist are the MRI scans already unzipped?
        T1_unzipped = 0;
        T2_unzipped = 0;
        % Check of the T1 MRI scan is unzipped
        no_files = size(files, 2);
        for file_no = 1:no_files
            file = files(1, file_no);
            if length(file)>16
                if file(1,:) == strcat(folder, '_defaced_T1w.nii')
                    T1_unzipped = 1; % T1 already unzipped
                    %fprintf("T1 already unzipped!\n");
                elseif file(1,:) == strcat(folder, '_defaced_T2w.nii')
                    T2_unzipped = 1; %T2 already unzipped
                    %fprintf("T2 already unzipped!\n");
                end
            end
        end


        % If T1 MRI is zipped, unzip
        if T1_unzipped == 0
            gunzip(strcat((parentDir), '/', folder, '/', 'anat', '/', folder, '_T1w.nii.gz'))
            %fprintf("T1 unzipped!\n");
        end
        % If T2 MRI is zipped, unzip
        if T2_unzipped == 0
            gunzip(strcat((parentDir), '/', folder, '/', 'anat', '/', folder, '_T2w.nii.gz'))
            %fprintf("T2 unzipped!\n");
        end

        fprintf("Roasting... %s\n", folder);
        stl_model_name = strcat(folder, '_stl');
        mri_directory = strcat((parentDir), '/', folder, '/', 'anat', '/');
        t1_filename = strcat(folder, '_T1w.nii');
        t2_filename = strcat(folder, '_T2w.nii');
        % Run ROAST
        % Note: Padding turned off due to excess CSF tissue generated when
        % zero padding is on.
        try
            %% CHOOSE MONTAGE %%
            fprintf("ROAST NOW %d\n", simNum);
            if simNum == 1 % Right DLPFC bipolar
                roast(char(strcat(mri_directory,t1_filename)),{'F4',1,'Cz',-1}, stl_model_name, ... % Right FLPFC
                    'elecType',{'disc','disc'},...
                    'elecSize',{[28.21 1], [28.21, 1]},...
                    'elecOri','ap','T2', char(strcat(mri_directory, t2_filename)), ...
                    'conductivities',struct('csf',0.85), ...
                    'resampling','on', 'zeroPadding', 50);

            elseif simNum == 2 % Left motor cortex bipolar
                roast(char(strcat(mri_directory,t1_filename)),{'C3',1,'Fp2',-1},stl_model_name, ... % Motor
                    'elecType',{'disc','disc'},...
                    'elecSize',{[28.21 1], [28.21, 1]},...
                    'elecOri','ap','T2', char(strcat(mri_directory, t2_filename)), ...
                    'conductivities',struct('csf',0.85), ...
                    'resampling','on', 'zeroPadding', 50);
            elseif simNum == 3 % CHANGE to occipital bipolar
                roast(char(strcat(mri_directory,t1_filename)),{'F3',1,'F4',-1},stl_model_name, ... % Frontal
                    'elecType',{'disc','disc'},...
                    'elecsize',{[28.21 1], [28.21, 1]},...
                    'elecOri','ap','T2', char(strcat(mri_directory, t2_filename)), ...
                    'conductivities',struct('csf',0.85), ...
                    'resampling','on', 'zeroPadding', 50);
            elseif simNum == 4 % Right DLPFC HD-tDCS
                roast(char(strcat(mri_directory,t1_filename)),{'F4',1,'F2',-0.25,'AF4',-0.25,'F6',-0.25,'FC4',-0.25},stl_model_name,...%4 Right DLPFC
                    'elecType',{'disc','disc','disc','disc','disc'},...
                    'elecSize',{[10, 1],[10, 1],[10, 1],[10, 1],[10, 1]},...
                    'elecOri','ap','T2',char(strcat(mri_directory,t2_filename)),...
                    'conductivities',struct('csf',0.85),...
                    'resampling', 'on',  'zeroPadding', 50);

            elseif simNum == 5 % Left motor cortex HD-tDCS
                roast(char(strcat(mri_directory,t1_filename)),{'C3',1,'P3',-0.25,'Cz',-0.25,'T7',-0.25,'F3',-0.25},stl_model_name,...%4 Motor
                    'elecType',{'disc','disc','disc','disc','disc'},...
                    'elecSize',{[10, 1],[10, 1],[10, 1],[10, 1],[10, 1]},...
                    'elecOri','ap','T2',char(strcat(mri_directory,t2_filename)),...
                    'conductivities',struct('csf',0.85),...
                    'resampling', 'on', 'zeroPadding', 50);
            elseif simNum == 6 % Left bipolar parietal
                roast(char(strcat(mri_directory,t1_filename)),{'P3',1,'Fp2',-1}, stl_model_name, ...
                    'elecType',{'disc','disc'},...
                    'elecSize',{[28.21 1], [28.21, 1]},...
                    'elecOri','ap','T2', char(strcat(mri_directory, t2_filename)), ...
                    'conductivities',struct('csf',0.85), ...
                    'resampling','on',  'zeroPadding', 50);
            elseif simNum == 7 % Parietal HD-tDCS
                roast(char(strcat(mri_directory,t1_filename)),{'P3',1,'P1',-0.25,'CP3',-0.25,'P5',-0.25,'PO3',-0.25},stl_model_name,...%4 Motor
                    'elecType',{'disc','disc','disc','disc','disc'},...
                    'elecSize',{[10, 1],[10, 1],[10, 1],[10, 1],[10, 1]},...
                    'elecOri','ap','T2',char(strcat(mri_directory,t2_filename)),...
                    'conductivities',struct('csf',0.85),...
                    'resampling', 'on', 'zeroPadding', 50);
            elseif simNum == 8 % Occipital HD-tDCS
                    roast(char(strcat(mri_directory,t1_filename)), {'PO8',1,'P6',-0.25,'PO4',-0.25,'P10',-0.25,'O10',-0.25},...
                    'elecType',{'disc','disc','disc','disc','disc'},...
                    'elecSize',{[10, 1],[10, 1],[10, 1],[10, 1],[10, 1]},...
                    'elecOri','ap','T2',char(strcat(mri_directory,t2_filename)),...
                    'conductivities',struct('csf',0.85),...
                    'resampling', 'on', 'zeroPadding', 50);

            elseif simNum == 9 % Cross hemisphere motor cortex
                roast(char(strcat(mri_directory,t1_filename)),{'C3',1,'C4',-1}, stl_model_name, ...
                    'elecType',{'disc','disc'},...
                    'elecSize',{[28.21 1], [28.21, 1]},...
                    'elecOri','ap','T2', char(strcat(mri_directory, t2_filename)), ...
                    'conductivities',struct('csf',0.85), ...
                    'resampling','on', 'zeroPadding', 50);
            elseif simNum == 10 % Bipolar medial frontal
                roast(char(strcat(mri_directory,t1_filename)),{'Fpz',1,'Oz',-1}, stl_model_name, ...
                    'elecType',{'disc','disc'},...
                    'elecSize',{[28.21 1], [28.21, 1]},...
                    'elecOri','ap','T2', char(strcat(mri_directory, t2_filename)), ...
                    'conductivities',struct('csf',0.85), ...
                    'resampling','on', 'zeroPadding', 50);
            end


            fprintf("---- ROAST COMPLETE %s  simNum %d------ \n", folder, simNum)
            %data.Var2(p) = 0; % Simulation completed so SimNum set to 0 to stop the simulation being repeated
            % writetable(data, '/shared/arvaneh_group/Shared/stimsim/sims2repeat.xlsx');
            parsave(strcat(mri_directory, 'complete.txt'));
            fprintf("Sim num set to 0. \n\n")
            close all;
        catch
            fprintf("@-@-@-@-@-      ERROR - ROAST NOT COMPLETE %s simNum %d      -@-@-@-@-@\n", folder, simNum)
        end
    end
end

delete(pool1)

function [subDirsNames] = ListFolders(parentDir)
% Get a list of all files and folders in parentDir folder.
files = dir(parentDir);
% Get a logical vector that tells which is a directory.
dirFlags = [files.isdir];
% Extract only those that are directories.
subDirs = files(dirFlags); % A structure with extra info.
% Get only the folder names into a cell array.
subDirsNames = {subDirs(3:end).name};
end


function [simGO] = segMapChecker(subjName)
data = readtable('CamCAN.xlsx');
simGO = 0;
for subj = 1:size(data, 1)
    if strcmp(data(subj, 2).Var2, subjName) % Find row for subject
        if data(subj, 1).Var1 == 1 % Check if segmap marked good
            simGO = true; % If segmap good, mark as so
        end
    end
end
end

function parsave(filePath)
    save(filePath);
    fprintf("Saved txt file.\n")
end

% function segMapZeroPadding(directory, fileName)
% segMap = niftiread(strcat(directory, fileName));
%
% ySize = size(segMap, 2);
% zSize = size(segMap, 3);
% tbPadding = zeros(20, ySize, zSize);
% segMap = [tbPadding; segMap; tbPadding];
%
% xSize = size(segMap, 1);
% zSize = size(segMap, 3);
% lrPadding = zeros(xSize, 20, zSize);
% segMap = cat(2, lrPadding, segMap);
% segMap = cat(2, segMap, lrPadding);
%
% xSize = size(segMap, 1);
% ySize = size(segMap, 2);
% bfPadding = zeros(xSize, ySize, 20);
% segMap = cat(3, bfPadding, segMap);
% segMap = cat(3, segMap, bfPadding);
%
% paddedSegMapName = strcat(fileName(1:25), 'padded50', fileName(25:end));
%
% niftiwrite(segMap, strcat(directory, paddedSegMapName));
%
% end
%






