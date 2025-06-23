function Mesh2Vtk(filename, faces, elems)
% writeBrainMeshVTK  Write a mixed‐triangle/quad mesh to legacy ASCII VTK.
%
%   writeBrainMeshVTK(fname, nodes, faces, elems)
%
%   - fname : string, path to .vtk file to create
%   - nodes : N×3 array of node coordinates [x y z]
%   - faces : F×3 array of triangle‐face node‐indices (1‐based)
%   - elems : E×4 array of quad‐element node‐indices (1‐based)
%
%  The resulting file is a POLYDATA dataset with triangles and quads.
%
%  Example:
%     nodes = rand(100,3);
%     faces = randi(100,3559,3);
%     elems = randi(100,3230,4);
%     writeBrainMeshVTK('brainMesh.vtk', nodes, faces, elems);
%

  nTri   = size(faces,1);
  nQuad  = size(elems,1);

  fid = fopen(filename,'w');
  assert(fid~=-1, 'Could not open %s for writing.', filename);

  %–– 1) Header
  fprintf(fid, '# vtk DataFile Version 3.0\n');
  fprintf(fid, 'Brain mesh exported from MATLAB\n');
  fprintf(fid, 'ASCII\n');
  fprintf(fid, 'DATASET POLYDATA\n');

  %–– 3) Cells (triangles + quads)
  % Legacy VTK expects a single CELLS section, so we concatenate.
  totalCells = nTri + nQuad;
  % Each entry needs one size‐prefix: 3 for triangles, 4 for quads.
  % So total integer count = sum(1 + Ni) over all cells
  totalIntCount = nTri*(1+3) + nQuad*(1+4);
  fprintf(fid, '\nCELLS %d %d\n', totalCells, totalIntCount);

  % Triangles
  for i=1:nTri
    fprintf(fid, '3 %d %d %d\n', faces(i,:) - 1);  % VTK is zero‐based
  end
  % Quads
  for i=1:nQuad
    fprintf(fid, '4 %d %d %d %d\n', elems(i,:) - 1);
  end

  %–– 4) Cell types: VTK_TRIANGLE=5, VTK_QUAD=9
  fprintf(fid, '\nCELL_TYPES %d\n', totalCells);
  fprintf(fid, '%d\n', repmat(5,nTri,1));   % triangles
  fprintf(fid, '%d\n', repmat(9,nQuad,1));  % quads

  fclose(fid);
  fprintf('Written %s with %d pts, %d tris, %d quads.\n', ...
          filename, nTri, nQuad);
end
