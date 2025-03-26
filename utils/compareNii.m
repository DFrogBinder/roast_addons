function compareNii(file1, file2)
% COMPARENIIFILES Interactively compare two .nii files.
%
%   compareNiiFiles(file1, file2) loads the two NIfTI files specified by
%   file1 and file2, and displays them side by side. A slider allows you to
%   scroll through the slices of the volumes.
%
%   Note: This function requires the NIfTI toolbox for MATLAB, which provides
%   the functions load_nii and save_nii.
%
% Example:
%   compareNiiFiles('subject1.nii', 'subject2.nii')

    % Load the NIfTI files
    nii1 = load_nii(file1);
    nii2 = load_nii(file2);
    
    % Extract image data
    data1 = nii1.img;
    data2 = nii2.img;
    
    % Verify that the dimensions match for a fair comparison
    if ~isequal(size(data1), size(data2))
        error('The two NIfTI files have different dimensions.');
    end
    
    % Assume 3D volumes and use the 3rd dimension as the slice dimension
    numSlices = size(data1, 3);
    
    % Create a figure with two subplots for side-by-side comparison
    hFig = figure('Name', 'NIfTI File Comparison', 'NumberTitle', 'off');
    
    % Display the first slice of the first volume
    hAx1 = subplot(1,2,1);
    hImg1 = imagesc(data1(:,:,1), 'Parent', hAx1);
    axis(hAx1, 'image');
    title(hAx1, sprintf('File 1:(Slice %d)', 1));
    colormap(hAx1, 'gray');
    colorbar('peer', hAx1);
    
    % Display the first slice of the second volume
    hAx2 = subplot(1,2,2);
    hImg2 = imagesc(data2(:,:,1), 'Parent', hAx2);
    axis(hAx2, 'image');
    title(hAx2, sprintf('File 2:(Slice %d)', 1));
    colormap(hAx2, 'gray');
    colorbar('peer', hAx2);
    
    % Create an interactive slider to scroll through slices
    hSlider = uicontrol('Style', 'slider', ...
                        'Min', 1, 'Max', numSlices, 'Value', 1, ...
                        'Units', 'normalized', ...
                        'Position', [0.25 0.02 0.5 0.05], ...
                        'SliderStep', [1/(numSlices-1) , 10/(numSlices-1)], ...
                        'Callback', @sliderCallback);
    
    % Nested function: Callback to update images when the slider is moved
    function sliderCallback(src, ~)
        slice = round(get(src, 'Value'));
        % Update the images for both subplots
        set(hImg1, 'CData', data1(:,:,slice));
        set(hImg2, 'CData', data2(:,:,slice));
        title(hAx1, sprintf('File 1: %s (Slice %d)', file1, slice));
        title(hAx2, sprintf('File 2: %s (Slice %d)', file2, slice));
    end

end
