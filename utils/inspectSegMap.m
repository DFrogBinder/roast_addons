function inspectSegMap(filePath)
% VISUALIZESEGMAP Interactively visualize a 3D NIfTI segmentation map.
%
%   visualizeSegMap(filePath) loads the segmentation map from the specified
%   NIfTI file (filePath) and displays it slice-by-slice. A slider allows you
%   to navigate through the slices, and impixelinfo shows the value of each pixel.
%
%   Example:
%       visualizeSegMap('segmentation.nii');

    % Load the NIfTI file (requires the NIfTI toolbox, e.g., load_nii)
    nii = load_nii(filePath);
    data = nii.img;
    
    % Ensure the data is 3D
    if ndims(data) ~= 3
        error('This function supports only 3D segmentation maps.');
    end
    
    numSlices = size(data, 3);
    
    % Create a figure for interactive visualization.
    hFig = figure('Name','Segmentation Map Viewer','NumberTitle','off');
    
    % Create axes and display the first slice.
    hAx = axes('Parent',hFig);
    hImg = imshow(data(:,:,1), []); %#ok<*MINV>
    title(hAx, sprintf('Slice %d of %d', 1, numSlices));
    
    % Enable interactive pixel information display.
    impixelinfo;
    
    % Create a slider for browsing through slices.
    hSlider = uicontrol('Style', 'slider', ...
                        'Min', 1, 'Max', numSlices, 'Value', 1, ...
                        'Units', 'normalized', ...
                        'Position', [0.25 0.02 0.5 0.05], ...
                        'SliderStep', [1/(numSlices-1) 10/(numSlices-1)], ...
                        'Callback', @sliderCallback);
    
    % Nested callback function for the slider.
    function sliderCallback(src, ~)
        slice = round(get(src, 'Value'));
        set(hImg, 'CData', data(:,:,slice));
        title(hAx, sprintf('Slice %d of %d', slice, numSlices));
    end

end
