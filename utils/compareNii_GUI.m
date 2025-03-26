function compareNii_GUI
% compareNii_GUI Creates a GUI to interactively compare two NIfTI files.
%
% The GUI allows you to:
%   - Browse for two NIfTI files.
%   - Launch an interactive comparison where a slider lets you scroll through
%     the slices of the volumes.
%
% This tool requires the NIfTI toolbox for MATLAB (with functions like load_nii).

    % Create the main GUI figure.
    hFig = figure('Name', 'Compare NIfTI Files', 'NumberTitle', 'off',...
                  'Position', [300 300 500 300]);
    
    % File 1 label, edit box, and browse button.
    uicontrol('Style','text','Position',[20 240 100 20],...
              'String','File 1:', 'HorizontalAlignment','left');
    hFile1 = uicontrol('Style','edit','Position',[130 240 200 25],'String','');
    uicontrol('Style','pushbutton','Position',[340 240 100 25],...
              'String','Browse','Callback',@browseFile1);
    
    % File 2 label, edit box, and browse button.
    uicontrol('Style','text','Position',[20 200 100 20],...
              'String','File 2:', 'HorizontalAlignment','left');
    hFile2 = uicontrol('Style','edit','Position',[130 200 200 25],'String','');
    uicontrol('Style','pushbutton','Position',[340 200 100 25],...
              'String','Browse','Callback',@browseFile2);
    
    % Run button to start the comparison.
    uicontrol('Style','pushbutton','Position',[200 150 100 30],...
              'String','Compare','Callback',@runComparison);
    
    % Log messages listbox.
    hLog = uicontrol('Style','listbox','Position',[20 20 450 100],...
                     'String',{},'Max',2,'Min',0);
    
    % --- Callback Functions ---
    
    % Browse for File 1.
    function browseFile1(~, ~)
        [file, path] = uigetfile({'*.nii;*.nii.gz','NIfTI files (*.nii, *.nii.gz)'}, ...
                                 'Select First NIfTI File');
        if file ~= 0
            set(hFile1, 'String', fullfile(path, file));
        end
    end

    % Browse for File 2.
    function browseFile2(~, ~)
        [file, path] = uigetfile({'*.nii;*.nii.gz','NIfTI files (*.nii, *.nii.gz)'}, ...
                                 'Select Second NIfTI File');
        if file ~= 0
            set(hFile2, 'String', fullfile(path, file));
        end
    end

    % Run the comparison.
    function runComparison(~, ~)
        file1 = get(hFile1, 'String');
        file2 = get(hFile2, 'String');
        if isempty(file1) || isempty(file2)
            errordlg('Please select both NIfTI files.', 'Error');
            return;
        end
        logMessage('Starting comparison...');
        try
            compareNii(file1, file2);
            logMessage('Comparison launched.');
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
function compareNii(file1, file2)
% compareNii Interactively compare two .nii files.
%
%   compareNii(file1, file2) loads the two NIfTI files specified by file1 and
%   file2, and displays them side by side. A slider allows you to scroll through
%   the slices of the volumes.
%
%   Note: This function requires the NIfTI toolbox for MATLAB (load_nii).
%
% Example:
%   compareNii('subject1.nii', 'subject2.nii')

    % Load the NIfTI files.
    nii1 = load_nii(file1);
    nii2 = load_nii(file2);
    
    % Extract image data.
    data1 = nii1.img;
    data2 = nii2.img;
    
    % Verify that the dimensions match.
    if ~isequal(size(data1), size(data2))
        error('The two NIfTI files have different dimensions.');
    end
    
    % Assume 3D volumes and use the third dimension as the slice dimension.
    numSlices = size(data1, 3);
    
    % Create a figure with two subplots for side-by-side comparison.
    hCompFig = figure('Name', 'NIfTI File Comparison', 'NumberTitle', 'off');
    
    % Display the first slice of the first volume.
    hAx1 = subplot(1,2,1);
    hImg1 = imagesc(data1(:,:,1), 'Parent', hAx1);
    axis(hAx1, 'image');
    title(hAx1, sprintf('File 1: (Slice %d)', 1));
    colormap(hAx1, 'gray');
    colorbar('peer', hAx1);
    
    % Display the first slice of the second volume.
    hAx2 = subplot(1,2,2);
    hImg2 = imagesc(data2(:,:,1), 'Parent', hAx2);
    axis(hAx2, 'image');
    title(hAx2, sprintf('File 2: (Slice %d)', 1));
    colormap(hAx2, 'gray');
    colorbar('peer', hAx2);
    
    % Create an interactive slider to scroll through slices.
    hSlider = uicontrol('Style', 'slider', ...
                        'Min', 1, 'Max', numSlices, 'Value', 1, ...
                        'Units', 'normalized', ...
                        'Position', [0.25 0.02 0.5 0.05], ...
                        'SliderStep', [1/(numSlices-1), 10/(numSlices-1)], ...
                        'Callback', @sliderCallback);
    
    % Nested function: Callback to update images when the slider is moved.
    function sliderCallback(src, ~)
        slice = round(get(src, 'Value'));
        % Update the images for both subplots.
        set(hImg1, 'CData', data1(:,:,slice));
        set(hImg2, 'CData', data2(:,:,slice));
        title(hAx1, sprintf('File 1: %s (Slice %d)', file1, slice));
        title(hAx2, sprintf('File 2: %s (Slice %d)', file2, slice));
    end

end
