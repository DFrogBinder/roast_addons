%% map_normals_to_nodes.m
% n_pref = map_normals_to_nodes(fem_nodes, V, vertex_normals)
%   For each FEM node (Nx3), find the closest mesh‐vertex normal.
%   Returns n_pref: N×3 unit‐vectors ready for calculate_envelope.
function n_pref = map_normals_to_nodes(fem_nodes, V, vertex_normals)
  % Build KD–tree on mesh vertices
  Mdl = createns(V, 'Distance','euclidean');
  % For each FEM node, find nearest vertex
  idx = knnsearch(Mdl, fem_nodes);
  % Grab its normal
  n_pref = vertex_normals(idx, :);
end
