function save_ef(ef_all, ef_mag, hdrInfo, outputDir, uniTag)
% save_ef  Save E-field & magnitude as compressed NIfTIs
% Inputs:
%   ef_all    : [nx×ny×nz×3] E-field components
%   ef_mag    : [nx×ny×nz]   E-field magnitude
%   hdrInfo   : struct with
%                  .dim    = [nx ny nz]
%                  .pixdim = [dx dy dz]
%                  .v2w    = 4×4 voxel→world affine
%   outputDir : output directory
%   uniTag    : filename prefix (e.g. 'subj1_sim1')

  if ~exist(outputDir,'dir')
    mkdir(outputDir);
  end

  % sanity checks
  assert(isequal(hdrInfo.dim, size(ef_mag)), ...
    'hdrInfo.dim [%s] ≠ size(ef_mag) [%s]', ...
    num2str(hdrInfo.dim), num2str(size(ef_mag)));
  assert(isequal([hdrInfo.dim,3], size(ef_all)), ...
    'hdrInfo.dim+[3] [%s] ≠ size(ef_all) [%s]', ...
    num2str([hdrInfo.dim,3]), num2str(size(ef_all)));

  % --- build a *clean* Info struct MATLAB will accept ---
  baseInfo = struct( ...
    'Datatype',        'single', ...             % float32
    'Transform',       hdrInfo.v2w, ...          % full affine
    'SpaceUnits',      {{'mm'}}, ...
    'TimeUnits',       {{'sec'}} ...
  );

  % 1) Scalar magnitude
  info = baseInfo;
  info.ImageSize       = hdrInfo.dim;
  info.PixelDimensions = hdrInfo.pixdim;
  disp(info)
  disp(fieldnames(info))

  outMag  = fullfile(outputDir, [uniTag '_emag.nii']);
  niftiwrite( single(ef_mag), outMag, info, ...
              'Compressed', true );

  % 2) 4-D vector field
  info    = baseInfo;
  info.ImageSize       = [hdrInfo.dim, 3];
  info.PixelDimensions = [hdrInfo.pixdim, 1];  % pad the 4th dim
  outVec  = fullfile(outputDir, [uniTag '_e.nii']);
  niftiwrite( single(ef_all), outVec, info, ...
              'Compressed', true );

  fprintf('Saved EF magnitude → %s.gz\n', outMag);
  fprintf('Saved EF vectors   → %s.gz\n', outVec);
end


