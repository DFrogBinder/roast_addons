function vertex_normals = compute_vertex_normals(V, F)
% COMPUTE_VERTEX_NORMALS  Unit normals at each mesh vertex
%   V: #V×3 vertex coords
%   F: #F×3 triangle indices into V
%   vertex_normals: #V×3 unit normals (zeros for isolated vertices)

  % 1) raw face normals
  v1 = V(F(:,2),:) - V(F(:,1),:);
  v2 = V(F(:,3),:) - V(F(:,1),:);
  fn = cross(v1, v2, 2);                % #F×3 unnormalized
  fn_norm = vecnorm(fn, 2, 2);          % #F×1

  % skip degenerate faces
  validF = fn_norm > eps;
  fn(~validF, :)    = 0;                % zero-out bad faces
  fn(validF, :)     = fn(validF, :) ./ fn_norm(validF);

  % 2) accumulate normals at each vertex
  vertex_normals = zeros(size(V));
  counts         = zeros(size(V,1),1);
  for fi = find(validF)'               % only loop over good faces
    vs = F(fi,:);
    vertex_normals(vs, :) = vertex_normals(vs, :) + fn(fi, :);
    counts(vs)            = counts(vs) + 1;
  end

  % 3) avoid divide-by-zero for isolated vertices
  nonIso = counts > 0;
  vertex_normals(nonIso, :) = vertex_normals(nonIso, :) ./ counts(nonIso);

  % 4) normalize per-vertex (zeros stay zero)
  vn_norm = vecnorm(vertex_normals, 2, 2);
  validV  = vn_norm > eps;
  vertex_normals(validV, :) = vertex_normals(validV, :) ./ vn_norm(validV);
end
