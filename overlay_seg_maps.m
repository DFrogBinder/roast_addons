function overlay_seg_maps(segFile,mriFile,SubjectID)
    
    disp('Fixing image orientation to RAS')
    [segFileRas,segFileisNonRAS] = convertToRAS(char(segFile));
    [mriFileRas,mriFileisNonRAS] = convertToRAS(char(mriFile));

    % Load MRI Data 
    mriVolume = niftiread(mriFileRas);
    mriVolume = flip(mriVolume,3);
    infoMRI   = niftiinfo(mriFile);
    numMRISlices = size(mriVolume, 3);
    fprintf('MRI Slices: %d\n', numMRISlices);
    
    % Load Segmentation Data
    segVolume = niftiread(segFileRas);
    segVolume = flip(segVolume,1);
    infoSeg   = niftiinfo(segFile);
    numSegSlices = size(segVolume, 3);
    fprintf('Segmentation Slices: %d\n', numSegSlices);
    
    
    % Create a Global Colormap
    globalUniqueLabels = unique(segVolume(:));
    numGlobalLabels = numel(globalUniqueLabels);
    globalColorMap = jet(numGlobalLabels);  % Create a colormap with enough colors
    
    % Get Number of Slices to Process
    numSlicesToProcess = min(numMRISlices, numSegSlices);
    fprintf('Processing %d slices...\n', numSlicesToProcess);
    
    % Setup Video Writer
    VideoName = SubjectID+"_Video.avi";
    VideoPath = fullfile("Workbench",VideoName);
    outputVideo = VideoWriter(VideoPath);  % Output video file name
    outputVideo.FrameRate = 10;  % Adjust frame rate as desired
    open(outputVideo);
    
    % Create a Figure for Display
    hFig = figure('Position', [100, 100, 1200, 600], 'Resize', 'off');
    
    % Loop through slices; here we use the same loop index for both views.
    for i = 1:numSlicesToProcess
        mriSliceAxial = mriVolume(:, :, i);
        mriSliceAxial_norm = mat2gray(mriSliceAxial);
        
        segSliceAxial = segVolume(:, :, i);
        segSliceAxialRGB = label2rgb(segSliceAxial, globalColorMap, 'k');
        
        [axRows, axCols] = size(mriSliceAxial_norm);
        [saxRows, saxCols, ~] = size(segSliceAxialRGB);
        if axRows ~= saxRows || axCols ~= saxCols
            segSliceAxialRGB = imresize(segSliceAxialRGB, [axRows, axCols]);
        end
        
        mriSliceCoronal = squeeze(mriVolume(:, i, :));
        mriSliceCoronal_norm = mat2gray(mriSliceCoronal);
        
        segSliceCoronal = squeeze(segVolume(:, i, :));
        segSliceCoronalRGB = label2rgb(segSliceCoronal, globalColorMap, 'k');
        
        [corRows, corCols] = size(mriSliceCoronal_norm);
        [scoRows, scoCols, ~] = size(segSliceCoronalRGB);
        if corRows ~= scoRows || corCols ~= scoCols
            segSliceCoronalRGB = imresize(segSliceCoronalRGB, [corRows, corCols]);
        end
        
        clf(hFig);
        
        % ----- DISPLAYING THE OVERLAYS -----
        subplot(1,2,1);
        imshow(mriSliceAxial_norm, []);
        hold on;
        hOverlayAxial = imshow(segSliceAxialRGB);
        set(hOverlayAxial, 'AlphaData', 0.1);
        hold off;
        title(sprintf('Axial Slice %d', i));
        
        subplot(1,2,2);
        imshow(imrotate(mriSliceCoronal_norm,270 ),[]);
        hold on;
        hOverlayCoronal = imshow(imrotate(segSliceCoronalRGB,270));
        set(hOverlayCoronal, 'AlphaData', 0.1);
        hold off;
        title(sprintf('Coronal Slice %d', i));
        
        drawnow;
        
        frame = getframe(hFig);
        resizedFrame = imresize(frame.cdata, [600, 1200]);
        writeVideo(outputVideo, resizedFrame);
    end
    
    % Close and Save the Video File
    close(outputVideo);
    fprintf('Video saved successfully as %s \n', VideoPath);
end