%% run_TI_simulations.m
% This script performs TI stimulation experiments for multiple subjects.
% For each subject, it:
%   1. Preprocesses the subject’s MRI and segmentation files.
%   2. Runs two simulations (TI_right and TI_left) with different electrode montages.
%   3. Once both simulations are complete, it computes the TI envelope.

close all;
clear all;

%% Settings
parentDir       = '/home/boyan/sandbox/Jake_Data/Example_data/';
subjectPattern  = 'sub-CC*';

% Simulation parameters
elecType        = {'disc', 'disc'};
elecSize        = {[10 1], [10 1]};
elecOri         = 'ap';
resamplingFlag  = 'on';
csfConductivity = 0.85;
zeroPadValue    = 50;

% Montage configurations
montage_right = {'PO7', 2, 'AF7', -2};
montage_left  = {'PO8', 2, 'AF8', -2};


%% List subjects
dirs = dir(fullfile(parentDir, subjectPattern));
numSubj = length(dirs);

%% Loop over subjects
for i = 1:numSubj
    close all
    subj = dirs(i).name;
    subjPath = fullfile(parentDir, subj);
    anatDir  = fullfile(subjPath, 'anat');
    fprintf('\n=== Processing %s ===\n', subj);

    %% Step 1: Preprocessing
    segMapFileName = cleanUpFiles(anatDir);
    t1_nii = fullfile(anatDir, [subj '_T1w.nii']);
    t2_nii = fullfile(anatDir, [subj '_T2w.nii']);
    t1_gz  = fullfile(anatDir, [subj '_T1w.nii.gz']);
    t2_gz  = fullfile(anatDir, [subj '_T2w.nii.gz']);
    if ~exist(t1_nii,'file') && exist(t1_gz,'file'), gunzip(t1_gz,anatDir); fprintf('Unzipped T1\n'); end
    if ~exist(t2_nii,'file') && exist(t2_gz,'file'), gunzip(t2_gz,anatDir); fprintf('Unzipped T2\n'); end
    segMapFile = findSegMapFile(anatDir);
    % if isempty(segMapFile), warning('No segmap, skip %s',subj); continue; end
    % zeroPadding(fullfile(anatDir,segMapFile), zeroPadValue);
    
    %% Step 2: Run ROAST simulations
    marker_r = fullfile(anatDir,'TI_right_complete.txt');
    marker_l = fullfile(anatDir,'TI_left_complete.txt');
    marker_TI = fullfile(anatDir,'TI_calculated.txt');

    % Right montage
    if ~exist(marker_r,'file')
        try
            fprintf('Running TI_right...\n');
            fwd_1 = roast(fullfile(anatDir,[subj '_T1w.nii']), montage_right, ...
                         'elecType',elecType,'elecSize',elecSize,'elecOri',elecOri, ...
                         'T2',fullfile(anatDir,[subj '_T2w.nii']), ...
                         'conductivities',struct('csf',csfConductivity), ...
                         'resampling',resamplingFlag,'zeroPadding',zeroPadValue);
            parsave(marker_r);
        catch ME
            fprintf('Error TI_right for %s: %s\n', subj, ME.message);
            continue;
        end
    else
        fprintf('TI_right already done.\n');
    end
    % Left montage
    close all
    if ~exist(marker_l,'file')
        try
            fprintf('Running TI_left...\n');
            fwd_2 = roast(fullfile(anatDir,[subj '_T1w.nii']), montage_left, ...
                         'elecType',elecType,'elecSize',elecSize,'elecOri',elecOri, ...
                         'T2',fullfile(anatDir,[subj '_T2w.nii']), ...
                         'conductivities',struct('csf',csfConductivity), ...
                         'resampling',resamplingFlag,'zeroPadding',zeroPadValue);
            parsave(marker_l);
        catch ME
            fprintf('Error TI_left for %s: %s\n', subj, ME.message);
            continue;
        end
    else
        fprintf('TI_left already done.\n');
    end

    %% Step 3: Compute TI envelope
    if exist(marker_r,'file') && exist(marker_l,'file') && ~exist(marker_TI,'file')
        
        fprintf('Computing TI envelope...')
        
        e_fp1 = fullfile(anatDir, [subj,'_T1w_',fwd_1.tag,'_e.pos']);
        e_fp2 = fullfile(anatDir, [subj,'_T1w_',fwd_2.tag,'_e.pos']);
        
        
        % visualizeRes(fwd_1.subject, ...
        %     fwd_1.subjRasRSPD, ...
        %     fwd_1.T2,nodes, ...
        %     fwd_1.elems, ...
        %     faces, ...
        %     fwd_1.injectCurrent, ...
        %     fwd_1.hdrInfo, ...
        %     fwd_1.tag, ...
        %     1, ...
        %     fwd_1.volume, ...
        %     fwd_1.FieldMag, ...
        %     node_env_ext)
        
        
        %% First Set of Electrodes
        % Brain geometry
        % First Set of Electrodes
        grayFace1 = fwd_1.faces(find(fwd_1.faces(:,4) == 2),1:3);
        grayElm1 = fwd_1.elems(find(fwd_1.elems(:,5) == 2),1:4);
        % grayNode1 = fwd_1.nodes(find(fwd_1.nodes(:,4) == 2.5),1:3);
        nodeTissueLabels1 = fwd_1.nodes(:,4);
        
        %--- define your brain subset of nodes
        brainLabel = 2.5;
        brainIdx1  = find(fwd_1.nodes(:,4) == brainLabel);
        grayNode1  = fwd_1.nodes(brainIdx1,1:3);
        
        % Only keep tets fully inside the brain subset (you probably already did this)
        mask = all( ismember(grayElm1, brainIdx1), 2 );
        grayElm1 = grayElm1(mask,:);
        
        % Now remap into 1…Nb
        [~, loc]    = ismember(grayElm1, brainIdx1);
        grayElm1 = reshape(loc, size(grayElm1));   % M×4 indices into grayNode1


        fid = fopen(e_fp1);
        fgetl(fid);
        C1 = textscan(fid,'%d %f %f %f'); 
        fclose(fid);
     

        % Get Brain-only efield
        % --- build full E-field array (nNodes x 3) ---
        nNodes   = size(fwd_1.nodes, 1);
        Efull1    = zeros(nNodes, 3);
        nodeIdx  = C1{1};                   % integer node IDs
        Evals    = [C1{2}, C1{3}, C1{4}];
        Efull1(nodeIdx, :) = Evals;          % insert into full array
        
        % --- grab tissue labels ---
        nodeTissueLabels = fwd_1.nodes(:,4);
        
        % --- isolate brain nodes & E-field (adjust label as needed) ---
        brainLabel = 2.5;                   % or [2 3] if you have multiple codes
        isBrain    = (nodeTissueLabels == brainLabel);
        BrainE1     = Efull1(isBrain, :);
        
        % Plotting Mesh Componenets
        figure;
        plot3(grayNode1(:,1), grayNode1(:,2), grayNode1(:,3), '.', 'MarkerSize', 1);
        xlabel('X');
        ylabel('Y');
        zlabel('Z');
        title('Brain-only Nodes (grayNode1)');
        axis equal;
        grid on;
         
        % figure;
        % plotmesh( grayNode1, grayElm1);  % light transparent
        % title('Brain-only tetrahedra (grayElm1)');


        %% Second Set of Electrodes
        grayFace2 = fwd_2.faces(find(fwd_2.faces(:,4) == 2),1:3);
        grayElm2 = fwd_2.elems(find(fwd_2.elems(:,5) == 2),1:4);
        % % grayNode2 = fwd_2.nodes(find(fwd_2.nodes(:,4) == 2.5),1:3);       
        nodeTissueLabels2 = fwd_2.nodes(:,4);
        
        %--- define your brain subset of nodes
        brainIdx2  = find(fwd_2.nodes(:,4) == brainLabel);

        % Only keep tets fully inside the brain subset (you probably already did this)
        mask = all( ismember(grayElm2, brainIdx2), 2 );
        grayElm2 = grayElm2(mask,:);
        
        % Now remap into 1…Nb
        [~, loc]    = ismember(grayElm2, brainIdx2);
        grayElm2 = reshape(loc, size(grayElm2));   % M×4 indices into grayNode1

        fid = fopen(e_fp2);
        fgetl(fid);
        C2 = textscan(fid,'%d %f %f %f'); 
        fclose(fid);

        % Get Brain-only efield
        % --- build full E-field array (nNodes x 3) ---
        nNodes   = size(fwd_2.nodes, 1);
        Efull2    = zeros(nNodes, 3);
        nodeIdx  = C2{1};                   % integer node IDs
        Evals    = [C2{2}, C2{3}, C2{4}];
        Efull2(nodeIdx, :) = Evals;          % insert into full array
        
        % --- grab tissue labels ---
        nodeTissueLabels = fwd_2.nodes(:,4);
        
        % --- isolate brain nodes & E-field (adjust label as needed) ---
        brainLabel = 2.5;                   % or [2 3] if you have multiple codes
        isBrain    = (nodeTissueLabels == brainLabel);
        BrainE2     = Efull2(isBrain, :);
       

        
        %% Mesh Interpolation
        %--- define your brain subset of nodes
        brainLabel = 2.5;
        brainIdx2  = find(fwd_2.nodes(:,4) == brainLabel);
        grayNode2  = fwd_2.nodes(brainIdx2,1:3);
        
        %--- pick only gray-matter tetrahedra
        oldElems = fwd_2.elems(fwd_2.elems(:,5) == 2, 1:4);
        
        %--- ensure every elem is fully in the subset (optional but safe)
        mask     = all(ismember(oldElems, brainIdx2), 2);
        oldElems = oldElems(mask, :);
        
        %--- remap original node IDs to new 1…N indices
        [~, loc] = ismember(oldElems, brainIdx2);
        grayElm2 = loc;  
        
        
        % Plotting Nodes
        figure;
        plot3(grayNode2(:,1), grayNode2(:,2), grayNode2(:,3), '.', 'MarkerSize', 1);
        xlabel('X');
        ylabel('Y');
        zlabel('Z');
        title('Brain Only Nodes (grayNode2)');
        axis equal;
        grid on;

        % %--- now run tsearchn on the subset mesh
        % [elemID, baryC] = tsearchn(grayNode2, grayElm2, grayNode1);
        % nOutside = sum(isnan(elemID));
        % fprintf('  %d / %d brain nodes lie outside mesh2 hull\n',nOutside, numel(elemID));
        % 
        % 
        % % Interpolate ef1 onto mesh2’s nodes
        % ef2_on1 = meshinterp(BrainE2, elemID, baryC, grayElm2);
        % 
        % %% Calculate Brain-only TI
        % Itot = montage_left{2} + montage_right{2}; 
        % ratio = montage_left{2} / montage_right{2};
        % [env_full,info] = calculate_envelope(BrainE1, ef2_on1, ratio, Itot);
        % 
        % 
        % %% Plot against the full mesh to avoid index remaping
        % % build a full node-value array
        % dataFull = [ fwd_1.nodes(:,1:3), nan(size(fwd_1.nodes,1),1) ];
        % dataFull(brainIdx1,4) = env_full.free;
        % 
        % % plot using full connectivity
        % faces_full = fwd_1.faces(fwd_1.faces(:,4)==2,1:3);
        % elems_full = fwd_1.elems(fwd_1.elems(:,5)==2,1:4);
        % 
        % figure; colormap(jet);
        % plotmesh(dataFull, faces_full, elems_full, 'LineStyle','none');
        % title('iso2mesh meshinterp')
        % axis equal;  colorbar;
        
        %% Scattered Intepolant
        % build three separate interpolants, one per E-field component
        Fx = scatteredInterpolant( grayNode2(:,1:3), BrainE2(:,1), 'linear');
        Fy = scatteredInterpolant( grayNode2(:,1:3), BrainE2(:,2), 'linear');
        Fz = scatteredInterpolant( grayNode2(:,1:3), BrainE2(:,3), 'linear');
        
        % now evaluate at your target nodes
        ef2_on1 = [ Fx( grayNode1(:,1:3) ), ...
                    Fy( grayNode1(:,1:3) ), ...
                    Fz( grayNode1(:,1:3) ) ];
        [env_full,info] = calculate_envelope(BrainE1, ef2_on1, ratio, Itot);

        dataFull = [ fwd_1.nodes(:,1:3), nan(size(fwd_1.nodes,1),1) ];
        dataFull(brainIdx1,4) = env_full.free;
       
        % plot using full connectivity
        faces_full = fwd_1.faces(fwd_1.faces(:,4)==2,1:3);
        elems_full = fwd_1.elems(fwd_1.elems(:,5)==2,1:4);
        
        figure; colormap(jet);
        plotmesh(dataFull, faces_full, elems_full, 'LineStyle','none');
        title('Scattered Intepolant (prefered)')
        axis equal;  colorbar;
        
        %% Plotting ef2 on both meshes
        % --- Prepare your field data and meshes ---
        % (this is your existing code, unmodified)
        % build three separate interpolants, one per E-field component
        Fx = scatteredInterpolant( grayNode2(:,1:3), BrainE2(:,1), 'linear');
        Fy = scatteredInterpolant( grayNode2(:,1:3), BrainE2(:,2), 'linear');
        Fz = scatteredInterpolant( grayNode2(:,1:3), BrainE2(:,3), 'linear');
        
        % evaluate at your target (original) nodes
        ef2_on1 = [ Fx( grayNode1(:,1:3) ), ...
                    Fy( grayNode1(:,1:3) ), ...
                    Fz( grayNode1(:,1:3) ) ];
        
        [env_full,info] = calculate_envelope(BrainE1, ef2_on1, ratio, Itot);
        
        % assemble your data vector (node-wise scalar = env_full.free)
        dataFull = [ fwd_1.nodes(:,1:3), nan(size(fwd_1.nodes,1),1) ];
        dataFull(brainIdx1,4) = sqrt(ef2_on1(:,1).^2+ef2_on1(:,2).^2+ef2_on1(:,3).^2);
        
        % get the “refined” mesh connectivity
        faces_full = fwd_1.faces(fwd_1.faces(:,4)==2,1:3);
        elems_full = fwd_1.elems(fwd_1.elems(:,5)==2,1:4);
        
        % now also prepare the *original* mesh connectivity
        % (here I assume you have another struct, e.g. fwd_orig,
        %  or you can simply reuse fwd_1 if it *was* your original —
        %  just change the variable names accordingly)
        faces_orig = fwd_2.faces(fwd_2.faces(:,4)==2,1:3);
        elems_orig = fwd_2.elems(fwd_2.elems(:,5)==2,1:4);
        
        % build the same scalar field on the original nodes
        dataOrig = [ fwd_2.nodes(:,1:3), nan(size(fwd_2.nodes,1),1) ];
        dataOrig(brainIdx2,4) = sqrt(BrainE2(:,1).^2+BrainE2(:,2).^2+BrainE2(:,3).^2);
        
        % --- Plot both in one figure with subplots ---
        figure;
        colormap(jet);
        
        % left: scattered/interpolated result on the refined mesh
        subplot(1,2,1);
        plotmesh(dataFull, faces_full, elems_full, 'LineStyle','none');
        title('Scattered Interpolant (refined)');
        axis equal off;
        colorbar;
        
        % right: same field on the original mesh
        subplot(1,2,2);
        plotmesh(dataOrig, faces_orig, elems_orig, 'LineStyle','none');
        title('Same Field on Original Mesh');
        axis equal off;
        colorbar;
        
        % overall title and sizing
        sgtitle('Field Comparison: Refined vs. Original Mesh');
        set(gcf, 'Position', [200 200 1000 450]);


        parsave(marker_TI);
        (marker_TI);
        fprintf('TI envelope done.');
    
    else
        fprintf('Skipping TI envelope (already done or waiting).');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Helper Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function write_vtk_polydata( filename, pts, tris, faceLabels, envelope )
    % write_vtk_polydata  Write a legacy VTK PolyData file with:
    %   - POINTS (xyz)
    %   - POLYGONS (triangles)
    %   - CELL_DATA/tissue (scalar label per face)
    %   - POINT_DATA/envelope (scalar per node)
    %
    % filename    string, e.g. 'fwdMesh.vtk'
    % pts         N×3 double
    % tris        M×3 zero‐based int
    % faceLabels  M×1 int
    % envelope    N×1 double
    
      N = size(pts,1);
      M = size(tris,1);
    
      fid = fopen(filename,'w');
      fprintf(fid, '# vtk DataFile Version 3.0\n');
      fprintf(fid, 'Mesh with tissue labels + envelope only\n');
      fprintf(fid, 'ASCII\n');
      fprintf(fid, 'DATASET POLYDATA\n');
    
      % --- write points ---
      fprintf(fid, 'POINTS %d float\n', N);
      fprintf(fid, '%g %g %g\n', pts');
    
      % --- write triangles ---
      fprintf(fid, 'POLYGONS %d %d\n', M, 4*M);
      for i = 1:M
        fprintf(fid, '3 %d %d %d\n', tris(i,1), tris(i,2), tris(i,3));
      end
    
      % --- write per-face (cell) labels ---
      fprintf(fid, 'CELL_DATA %d\n', M);
      fprintf(fid, 'SCALARS tissue int 1\n');
      fprintf(fid, 'LOOKUP_TABLE default\n');
      fprintf(fid, '%d\n', faceLabels);
    
      % --- write per-point (node) envelope ---
      fprintf(fid, 'POINT_DATA %d\n', N);
      fprintf(fid, 'SCALARS envelope float 1\n');
      fprintf(fid, 'LOOKUP_TABLE default\n');
      fprintf(fid, '%g\n', envelope);
    
      fclose(fid);
end

function segMapFileName = cleanUpFiles(anatDir)
    % Delete all files except for original MRI and segmap
    folder_contents = dir(anatDir);
    files = struct2cell(folder_contents);
    
    no_files = size(files, 2);
    if no_files > 4
        for file_no = 1:no_files % Loop through al files
            file = files(1, file_no);
            file = file{1};
           if length(file)>11 % Only check long filenames
                % Keep original MRI and mask
                if ~strcmp(file(end-6:end), '.nii.gz') &&  ~strcmp(file(end-9:end), '_masks.nii')
                    fprintf("Deleted %s \n", file)
                    delete(fullfile(anatDir, file))
                elseif strcmp(file(end-9:end), '_masks.nii')
                    if length(file) > 50
                        fprintf("Deleted %s \n", file)
                         delete(fullfile(anatDir, file))
                    else
                        segMapFileName = file;
                    end
                end
    
            elseif length(file)> 2
                fprintf("Deleted %s \n", file)
                delete(fullfile(anatDir, file))
            end
        end
    end
end

function segMapFile = findSegMapFile(anatDir)
    % findSegMapFile searches for a file ending with '_masks.nii' in anatDir.
    segMapFile = '';
    files = dir(anatDir);
    for j = 1:length(files)
        if ~files(j).isdir && endsWith(files(j).name, '_masks.nii')
            segMapFile = files(j).name;
            return;
        end
    end
end

function parsave(filePath)
    % robustParsave creates a marker file with additional metadata (timestamp)
    % using a temporary file to ensure atomic write operations.
    tempFile = [filePath, '.tmp'];
    fid = fopen(tempFile, 'w');
    if fid == -1
        error('Could not open temporary file for writing: %s', tempFile);
    end
    timestamp = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss');
    fprintf(fid, 'Status: Done\nTimestamp: %s\n', timestamp);
    fclose(fid);
    % Atomically move temporary file to final marker file
    status = movefile(tempFile, filePath, 'f');
    if ~status
        error('Could not move temporary marker file to final location: %s', filePath);
    else
        fprintf('Created robust marker file: %s\n', filePath);
    end
end

function zeroPadding(segMapFile, padVal)
    % zeroPadding applies zero padding to the segmentation map.
    % Replace the contents of this function with your actual padding code.
    fprintf('Applying zero padding to %s with pad value %d.\n', segMapFile, padVal);
    % Example (commented):
    % segMap = niftiread(segMapFile);
    % paddedSegMap = padarray(segMap, [padVal padVal padVal], 0, 'both');
    % niftiwrite(paddedSegMap, segMapFile);
end
