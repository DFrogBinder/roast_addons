function decompose_segMap_GUI
% decompose_segMap_GUI Creates a GUI to interactively decompose a segmentation
% NIfTI file into separate tissue maps.
%
% The GUI allows you to:
%   - Enter a subject name.
%   - Browse for an input NIfTI file.
%   - Browse for an output directory.
%   - Run the decomposition process.
%
% The underlying decompose_segMap function will process both 3D label maps
% (by creating binary masks for each unique label) and 4D probability maps
% (by preserving continuous values), flipping the data along the third
% dimension to match SPM orientation.

    % Create the GUI figure.
    hFig = figure('Name', 'Decompose Segmentation Map', 'NumberTitle', 'off',...
                  'Position', [300 300 500 350]);
    
    % Subject Name label and edit box.
    uicontrol('Style','text','Position',[20 300 100 20],...
              'String','Subject Name:', 'HorizontalAlignment', 'left');
    hSubject = uicontrol('Style','edit','Position',[130 300 200 25],'String','');
    
    % Input File label, edit box, and browse button.
    uicontrol('Style','text','Position',[20 260 100 20],...
              'String','Input File:', 'HorizontalAlignment', 'left');
    hInput = uicontrol('Style','edit','Position',[130 260 200 25],'String','');
    uicontrol('Style','pushbutton','Position',[340 260 100 25],...
              'String','Browse','Callback',@browseInput);
    
    % Output Directory label, edit box, and browse button.
    uicontrol('Style','text','Position',[20 220 100 20],...
              'String','Output Directory:', 'HorizontalAlignment', 'left');
    hOutput = uicontrol('Style','edit','Position',[130 220 200 25],'String','');
    uicontrol('Style','pushbutton','Position',[340 220 100 25],...
              'String','Browse','Callback',@browseOutput);
    
    % Run button to start the decomposition.
    uicontrol('Style','pushbutton','Position',[200 170 100 30],...
              'String','Run','Callback',@runDecompose);
    
    % Log messages listbox.
    hLog = uicontrol('Style','listbox','Position',[20 20 450 130],...
                     'String',{},'Max',2,'Min',0);
    
    % --- Callback Functions ---
    
    % Browse for the input file.
    function browseInput(~,~)
        [file, path] = uigetfile({'*.nii;*.nii.gz','NIfTI files (*.nii, *.nii.gz)'}, ...
                                 'Select Input NIfTI File');
        if file ~= 0
            set(hInput, 'String', fullfile(path, file));
        end
    end

    % Browse for the output directory.
    function browseOutput(~,~)
        folder = uigetdir;
        if folder ~= 0
            set(hOutput, 'String', folder);
        end
    end

    % Run the decomposition process.
    function runDecompose(~,~)
        subject_name = get(hSubject, 'String');
        input_file   = get(hInput, 'String');
        output_dir   = get(hOutput, 'String');
        if isempty(subject_name) || isempty(input_file) || isempty(output_dir)
            errordlg('Please fill in all fields', 'Error');
            return;
        end
        logMessage('Starting decomposition...');
        try
            decompose_segMap(subject_name, input_file, output_dir);
            logMessage('Decomposition completed successfully.');
        catch ME
            logMessage(['Error: ', ME.message]);
            errordlg(ME.message, 'Error');
        end
    end

    % Update the log messages.
    function logMessage(msg)
        currLog = get(hLog, 'String');
        newLog = [currLog; {msg}];
        set(hLog, 'String', newLog);
        drawnow;
    end

end

% -------------------------------------------------------------------------
% The decompose_segMap function performs the actual file processing.
% -------------------------------------------------------------------------
function decompose_segMap(subject_name, input_file, output_dir)
% decompose_segMap Loads a NIfTI segmentation file and decomposes it into
% separate tissue maps.
%
%   decompose_segMap(subject_name, input_file, output_dir)
%
%   For a 4D NIfTI file (where each volume is a tissue probability map with
%   continuous values between 0 and 1), the function extracts each volume,
%   flips it along the third dimension (to match SPM orientation), and saves it
%   without altering its continuous values.
%
%   For a 3D NIfTI file (assumed to be a label map), the function creates a
%   binary mask for each unique label (0 and 1) and flips each mask along the
%   third dimension.
%
%   Example:
%       decompose_segMap('subject1', 'segmentation.nii', 'output_masks');

    % Create the output directory if it does not exist.
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    % Load the NIfTI segmentation file.
    nii = load_nii(input_file);
    data = nii.img;
    
    % Check the dimensionality of the data.
    if ndims(data) == 4
        % 4D case: Assume each 3D volume is a tissue probability map.
        numTissues = size(data, 4);
        fprintf('Detected 4D segmentation with %d tissue probability maps.\n', numTissues);
        for t = 1:numTissues
            % Extract the t-th tissue probability map.
            tissueMap = data(:, :, :, t);
            % Flip along the third dimension to match SPM orientation.
            tissueMap = flip(tissueMap, 3);
            % Copy the original NIfTI structure and update the image data.
            nii_tissue = nii;
            nii_tissue.img = tissueMap;
            % Save the probability map preserving its continuous values.
            output_filename = fullfile(output_dir, sprintf('c%s-%d_T1w_ras_1mm_T1andT2.nii', subject_name, t));
            save_nii(nii_tissue, output_filename);
            fprintf('Saved tissue probability map %d to %s\n', t, output_filename);
        end
    else
        % 3D case: Assume a label map where each voxel has a discrete label.
        tissue_labels = unique(data);
        fprintf('Detected 3D segmentation with tissue labels: %s\n', mat2str(tissue_labels));
        for i = 1:length(tissue_labels)
            label = tissue_labels(i);
            % Create a binary mask: voxels equal to the label become 1, otherwise 0.
            mask = (data == label);
            % Flip the mask along the third dimension.
            mask = flip(mask, 3);
            % Copy the original NIfTI structure and update the image data.
            nii_mask = nii;
            % Convert the binary mask to uint8.
            nii_mask.img = uint8(mask);
            output_filename = fullfile(output_dir, sprintf('c%d%s_T1w_ras_1mm_T1andT2.nii', label, subject_name));
            save_nii(nii_mask, output_filename);
            fprintf('Saved tissue label %d mask to %s\n', label, output_filename);
        end
    end
end
