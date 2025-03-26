% visualize_nii_interactive.m
% This script loads a NIfTI file and displays interactive views of the image.
% Three sliders allow the user to scroll through the axial, sagittal, and coronal slices.
%
% Note: Requires MATLAB R2018b or later for niftiread/niftiinfo.
%
% Run this script and use the file selection dialog to choose your .nii or .nii.gz file.

function view_nii
    % Select the NIfTI file
    [filename, pathname] = uigetfile({'*.nii;*.nii.gz','NIfTI Files (*.nii, *.nii.gz)'}, 'Select a NIfTI file');
    if isequal(filename, 0)
        disp('File selection canceled.');
        return;
    end
    nii_file = fullfile(pathname, filename);

    % Load image info and data
    info = niftiinfo(nii_file);
    img = niftiread(info);
    
    % If image is 4D (e.g., a time series), use the first volume
    if ndims(img) > 3
        img = img(:,:,:,1);
    end
    dims = size(img);  % dims = [X Y Z]

    % Default slice indices: center slices for each orientation
    axialIndex = round(dims(3) / 2);
    sagittalIndex = round(dims(1) / 2);
    coronalIndex = round(dims(2) / 2);

    % Create a figure for the interactive viewer
    fig = figure('Name', 'Interactive NIfTI Viewer', 'NumberTitle', 'off', 'Position', [100 100 900 600]);

    % Create subplots for the three orthogonal views
    % Axial view (slice along Z): image in the X-Y plane
    ax1 = subplot(2,3,1);
    hAxial = imagesc(img(:,:,axialIndex)); %#ok<NASGU>
    axis image off;
    colormap(gray);
    title(sprintf('Axial (Slice %d)', axialIndex));

    % Sagittal view (slice along X): image in the Y-Z plane
    ax2 = subplot(2,3,2);
    hSagittal = imagesc(squeeze(img(sagittalIndex,:,:))');
    axis image off;
    colormap(gray);
    title(sprintf('Sagittal (Slice %d)', sagittalIndex));

    % Coronal view (slice along Y): image in the X-Z plane
    ax3 = subplot(2,3,3);
    hCoronal = imagesc(squeeze(img(:,coronalIndex,:))');
    axis image off;
    colormap(gray);
    title(sprintf('Coronal (Slice %d)', coronalIndex));

    % Add sliders below each subplot (using normalized figure coordinates)
    % Axial slider: controls slice along Z-axis
    sAxial = uicontrol('Style', 'slider', ...
        'Min', 1, 'Max', dims(3), 'Value', axialIndex, ...
        'Units', 'normalized', 'Position', [0.10 0.10 0.25 0.05], ...
        'Callback', @(src,evt) updateAxial(round(get(src, 'Value'))));
    uicontrol('Style','text','Units','normalized','Position',[0.10 0.16 0.25 0.03],...
        'String','Axial Slice','BackgroundColor',get(gcf,'Color'));

    % Sagittal slider: controls slice along X-axis
    sSagittal = uicontrol('Style', 'slider', ...
        'Min', 1, 'Max', dims(1), 'Value', sagittalIndex, ...
        'Units', 'normalized', 'Position', [0.40 0.10 0.25 0.05], ...
        'Callback', @(src,evt) updateSagittal(round(get(src, 'Value'))));
    uicontrol('Style','text','Units','normalized','Position',[0.40 0.16 0.25 0.03],...
        'String','Sagittal Slice','BackgroundColor',get(gcf,'Color'));

    % Coronal slider: controls slice along Y-axis
    sCoronal = uicontrol('Style', 'slider', ...
        'Min', 1, 'Max', dims(2), 'Value', coronalIndex, ...
        'Units', 'normalized', 'Position', [0.70 0.10 0.25 0.05], ...
        'Callback', @(src,evt) updateCoronal(round(get(src, 'Value'))));
    uicontrol('Style','text','Units','normalized','Position',[0.70 0.16 0.25 0.03],...
        'String','Coronal Slice','BackgroundColor',get(gcf,'Color'));

    % Callback functions to update each view based on slider values.
    function updateAxial(newIndex)
        % Ensure index is within valid bounds
        newIndex = max(1, min(dims(3), newIndex));
        % Update the axial image
        subplot(ax1);
        imagesc(img(:,:,newIndex));
        axis image off;
        title(sprintf('Axial (Slice %d)', newIndex));
    end

    function updateSagittal(newIndex)
        newIndex = max(1, min(dims(1), newIndex));
        subplot(ax2);
        imagesc(squeeze(img(newIndex,:,:))');
        axis image off;
        title(sprintf('Sagittal (Slice %d)', newIndex));
    end

    function updateCoronal(newIndex)
        newIndex = max(1, min(dims(2), newIndex));
        subplot(ax3);
        imagesc(squeeze(img(:,newIndex,:))');
        axis image off;
        title(sprintf('Coronal (Slice %d)', newIndex));
    end
end

